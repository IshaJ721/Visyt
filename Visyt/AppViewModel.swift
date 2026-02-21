import Foundation
import CoreLocation
import UserNotifications
import Combine

class AppViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Role
    @Published var role: AppRole {
        didSet { UserDefaults.standard.set(role.rawValue, forKey: "role") }
    }

    // MARK: - Cafes
    @Published var cafes: [Cafe] = [] {
        didSet { save(cafes, key: "cafes") }
    }

    // MARK: - Active Session
    @Published var activeSession: Session? {
        didSet { save(activeSession, key: "activeSession") }
    }

    // MARK: - History & Wallet
    @Published var sessionHistory: [Session] = [] {
        didSet { save(sessionHistory, key: "sessionHistory") }
    }
    @Published var walletCredit: Double = 0.0 {
        didSet { UserDefaults.standard.set(walletCredit, forKey: "walletCredit") }
    }
    @Published var transactions: [Transaction] = [] {
        didSet { save(transactions, key: "transactions") }
    }

    // MARK: - Location
    @Published var userLocation: CLLocation?
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()

    // MARK: - UI State
    @Published var selectedCafe: Cafe?
    @Published var showCheckIn = false
    @Published var showSession = false

    // MARK: - Timer
    @Published var timeRemaining: TimeInterval = 0
    private var timerCancellable: AnyCancellable?

    // MARK: - Init

    /// Bump this whenever demo cafe data changes to force a refresh from UserDefaults cache.
    private let dataVersion = "v3-austin"

    override init() {
        let rawRole = UserDefaults.standard.string(forKey: "role") ?? ""
        self.role = AppRole(rawValue: rawRole) ?? .none

        super.init()

        // Reset cafe data if app version changed (clears stale SF locations)
        if UserDefaults.standard.string(forKey: "dataVersion") == dataVersion {
            cafes = load([Cafe].self, key: "cafes") ?? Cafe.demoData
        } else {
            cafes = Cafe.demoData
            UserDefaults.standard.set(dataVersion, forKey: "dataVersion")
        }
        activeSession = load(Session.self, key: "activeSession")
        sessionHistory = load([Session].self, key: "sessionHistory") ?? []
        walletCredit = UserDefaults.standard.double(forKey: "walletCredit")
        transactions = load([Transaction].self, key: "transactions") ?? []

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        requestNotificationPermission()

        if let session = activeSession, session.isActive {
            showSession = true
            startTimer(endTime: session.endTime)
        }
    }

    // MARK: - Location

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    func distance(to cafe: Cafe) -> String {
        guard let loc = userLocation else { return "–" }
        let cafeLoc = CLLocation(latitude: cafe.latitude, longitude: cafe.longitude)
        let meters = loc.distance(from: cafeLoc)
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    // MARK: - Check-In

    func checkIn(cafe: Cafe) {
        guard cafe.seatsAvailable > 0 else { return }

        let now = Date()
        let end = now.addingTimeInterval(Double(cafe.sessionMinutes) * 60)

        let session = Session(
            cafeID: cafe.id,
            cafeName: cafe.name,
            startTime: now,
            endTime: end,
            price: cafe.pricePerSession,
            userName: "You"
        )
        activeSession = session

        // Deduct seat
        if let idx = cafes.firstIndex(where: { $0.id == cafe.id }) {
            cafes[idx].seatsAvailable = max(0, cafes[idx].seatsAvailable - 1)
        }

        // Wallet credit ($0.50 back per session)
        let credit = 0.50
        walletCredit += credit
        transactions.append(Transaction(
            date: now,
            description: "Session at \(cafe.name)",
            amount: -cafe.pricePerSession
        ))
        transactions.append(Transaction(
            date: now,
            description: "Cashback reward",
            amount: credit
        ))

        scheduleNotification(minutesBefore: 10, endTime: end, cafeName: cafe.name)
        startTimer(endTime: end)
        showSession = true
        showCheckIn = false
    }

    // MARK: - Extend Session

    func extendSession() {
        guard var session = activeSession else { return }
        session.endTime = session.endTime.addingTimeInterval(30 * 60)
        activeSession = session
        walletCredit = max(0, walletCredit - 1.0)
        transactions.append(Transaction(
            date: Date(),
            description: "Session extension at \(session.cafeName)",
            amount: -1.0
        ))
        startTimer(endTime: session.endTime)
        scheduleNotification(minutesBefore: 10, endTime: session.endTime, cafeName: session.cafeName)
    }

    // MARK: - End Session

    func endSession() {
        timerCancellable?.cancel()
        if let session = activeSession {
            var finished = session
            finished.endTime = Date()
            sessionHistory.append(finished)

            // Restore seat
            if let idx = cafes.firstIndex(where: { $0.id == session.cafeID }) {
                cafes[idx].seatsAvailable = min(cafes[idx].totalSeats, cafes[idx].seatsAvailable + 1)
            }
        }
        activeSession = nil
        showSession = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Timer

    private func startTimer(endTime: Date) {
        timerCancellable?.cancel()
        timeRemaining = endTime.timeIntervalSinceNow
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.timeRemaining = endTime.timeIntervalSinceNow
                if self.timeRemaining <= 0 {
                    self.endSession()
                }
            }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(minutesBefore: Int, endTime: Date, cafeName: String) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let triggerDate = endTime.addingTimeInterval(-Double(minutesBefore) * 60)
        guard triggerDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Session ending soon"
        content.body = "Your session at \(cafeName) ends in \(minutesBefore) minutes."
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "sessionEnd", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Merchant helpers

    func activeSessions(for cafe: Cafe) -> [Session] {
        guard let s = activeSession, s.cafeID == cafe.id, s.isActive else { return [] }
        return [s]
    }

    func todayRevenue(for cafe: Cafe) -> Double {
        let calendar = Calendar.current
        return sessionHistory
            .filter { $0.cafeID == cafe.id && calendar.isDateInToday($0.startTime) }
            .reduce(0) { $0 + $1.price }
    }

    // MARK: - Merchant controls

    func toggleParticipating(cafe: Cafe) {
        guard let idx = cafes.firstIndex(where: { $0.id == cafe.id }) else { return }
        cafes[idx].isParticipating.toggle()
    }

    func setSeats(_ seats: Int, for cafe: Cafe) {
        guard let idx = cafes.firstIndex(where: { $0.id == cafe.id }) else { return }
        cafes[idx].totalSeats = max(1, seats)
        cafes[idx].seatsAvailable = min(cafes[idx].seatsAvailable, cafes[idx].totalSeats)
    }

    func setPrice(_ price: Double, for cafe: Cafe) {
        guard let idx = cafes.firstIndex(where: { $0.id == cafe.id }) else { return }
        cafes[idx].pricePerSession = max(0.5, price)
    }

    func setDuration(_ minutes: Int, for cafe: Cafe) {
        guard let idx = cafes.firstIndex(where: { $0.id == cafe.id }) else { return }
        cafes[idx].sessionMinutes = max(15, minutes)
    }

    // MARK: - Reset

    func resetDemoData() {
        cafes = Cafe.demoData
        activeSession = nil
        sessionHistory = []
        walletCredit = 0
        transactions = []
        timerCancellable?.cancel()
        showSession = false
        showCheckIn = false
        selectedCafe = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Persistence helpers

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - AppRole

enum AppRole: String, CaseIterable {
    case none, user, merchant

    var displayName: String {
        switch self {
        case .none: return "None"
        case .user: return "User"
        case .merchant: return "Merchant"
        }
    }
}
