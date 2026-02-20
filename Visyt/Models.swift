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
            Cafe(
                name: "Sightglass Coffee",
                neighborhood: "SoMa",
                description: "A sprawling, light-filled warehouse space with sky-high ceilings and the best pour-overs in the city. Great for deep work sessions.",
                latitude: 37.7749, longitude: -122.4194,
                vibeTags: ["Quiet", "Fast WiFi", "Power Outlets"],
                totalSeats: 12, seatsAvailable: 8,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "merchant1"      // ← the merchant's shop
            ),

            Cafe(
                name: "Ritual Coffee",
                neighborhood: "Hayes Valley",
                description: "A neighbourhood staple with warm wood tones and a loyal creative crowd. Expect lively background buzz and exceptional espresso drinks.",
                latitude: 37.7759, longitude: -122.4245,
                vibeTags: ["Lively", "Espresso", "Communal Tables"],
                totalSeats: 8, seatsAvailable: 3,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),

            Cafe(
                name: "Four Barrel Coffee",
                neighborhood: "Mission",
                description: "An airy, exposed-brick café perfect for long afternoons. The bookshelf wall and soft lighting make it a favourite for writers and remote workers.",
                latitude: 37.7643, longitude: -122.4215,
                vibeTags: ["Cozy", "Bookshelf", "Low Key"],
                totalSeats: 10, seatsAvailable: 10,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: false,
                ownerID: "other"
            ),

            Cafe(
                name: "Verve Coffee",
                neighborhood: "Castro",
                description: "Bright, plant-lined walls and a large outdoor patio make this the go-to for sunny day working. Fast WiFi and friendly staff seal the deal.",
                latitude: 37.7609, longitude: -122.4350,
                vibeTags: ["Outdoor Seating", "Fast WiFi", "Plants"],
                totalSeats: 6, seatsAvailable: 6,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),
        ]
    }
}
