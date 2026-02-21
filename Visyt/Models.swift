import Foundation
import CoreLocation

// MARK: - Cafe

struct Cafe: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var neighborhood: String
    var description: String
    var latitude: Double
    var longitude: Double
    var vibeTags: [String]
    var totalSeats: Int
    var seatsAvailable: Int
    var pricePerSession: Double
    var sessionMinutes: Int
    var isParticipating: Bool
    var ownerID: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func == (lhs: Cafe, rhs: Cafe) -> Bool { lhs.id == rhs.id }
}

// MARK: - Session

struct Session: Identifiable, Codable {
    var id: UUID = UUID()
    var cafeID: UUID
    var cafeName: String
    var startTime: Date
    var endTime: Date
    var price: Double
    var userName: String

    var timeRemaining: TimeInterval { endTime.timeIntervalSinceNow }
    var isActive: Bool { timeRemaining > 0 }
}

// MARK: - Transaction

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var description: String
    var amount: Double
}

// MARK: - Demo Data

extension Cafe {
    static var demoData: [Cafe] {
        [
            // Near UT Austin — real locations
            Cafe(
                name: "Caffe Medici",
                neighborhood: "The Drag",
                description: "Right on Guadalupe across from UT, this espresso-forward staple draws students and professors alike. Marble counters, soft lighting, and some of the best cappuccinos in Austin.",
                latitude: 30.2906, longitude: -97.7430,
                vibeTags: ["Quiet", "Fast WiFi", "Espresso"],
                totalSeats: 14, seatsAvailable: 9,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "merchant1"      // ← the merchant's shop
            ),

            Cafe(
                name: "Spider House Café",
                neighborhood: "West Campus",
                description: "An Austin institution steps from campus. Covered outdoor patios strung with lights, mismatched furniture, and a buzzing creative energy that makes long study sessions feel effortless.",
                latitude: 30.2963, longitude: -97.7497,
                vibeTags: ["Outdoor Patio", "Lively", "Late Night"],
                totalSeats: 20, seatsAvailable: 12,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),

            Cafe(
                name: "Epoch Coffee",
                neighborhood: "North Loop",
                description: "Open 24/7 and beloved for it. Epoch is the go-to for night owls and early risers, with a warm neighbourhood feel, strong cold brew, and always-reliable WiFi.",
                latitude: 30.3163, longitude: -97.7267,
                vibeTags: ["24/7", "Cold Brew", "Power Outlets"],
                totalSeats: 18, seatsAvailable: 18,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: false,
                ownerID: "other"
            ),

            Cafe(
                name: "Houndstooth Coffee",
                neighborhood: "Downtown",
                description: "Sleek, minimal, and serious about coffee. Houndstooth's downtown location draws the after-class crowd with precision brews, fast WiFi, and plenty of desk space near the windows.",
                latitude: 30.2669, longitude: -97.7430,
                vibeTags: ["Minimal", "Fast WiFi", "Window Seats"],
                totalSeats: 10, seatsAvailable: 6,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),
        ]
    }
}
