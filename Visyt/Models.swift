import Foundation
import CoreLocation

// MARK: - Cafe

struct Cafe: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var neighborhood: String
    var description: String
    var venueType: String = "Café"   // e.g. "Café", "Hotel", "Event Venue", "Library"
    var latitude: Double
    var longitude: Double
    var vibeTags: [String]
    var totalSeats: Int
    var seatsAvailable: Int
    var pricePerSession: Double
    var sessionMinutes: Int
    var isParticipating: Bool
    var ownerID: String

    var pinIcon: String {
        switch venueType {
        case "Hotel":       return "bed.double.fill"
        case "Event Venue": return "theatermasks.fill"
        case "Library":     return "books.vertical.fill"
        default:            return "cup.and.saucer.fill"
        }
    }

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
            // ── Cafés ──────────────────────────────────────────────
            Cafe(
                name: "Caffe Medici",
                neighborhood: "The Drag",
                description: "Right on Guadalupe across from UT, this espresso-forward staple draws students and professors alike. Marble counters, soft lighting, and some of the best cappuccinos in Austin.",
                venueType: "Café",
                latitude: 30.2906, longitude: -97.7430,
                vibeTags: ["Quiet", "Fast WiFi", "Espresso"],
                totalSeats: 14, seatsAvailable: 9,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "merchant1"
            ),

            Cafe(
                name: "Spider House Café",
                neighborhood: "West Campus",
                description: "An Austin institution steps from campus. Covered outdoor patios strung with lights, mismatched furniture, and a buzzing creative energy that makes long study sessions feel effortless.",
                venueType: "Café",
                latitude: 30.2963, longitude: -97.7497,
                vibeTags: ["Outdoor Patio", "Lively", "Late Night"],
                totalSeats: 20, seatsAvailable: 12,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),

            Cafe(
                name: "Houndstooth Coffee",
                neighborhood: "Downtown",
                description: "Sleek, minimal, and serious about coffee. Houndstooth's downtown location draws the after-class crowd with precision brews, fast WiFi, and plenty of desk space near the windows.",
                venueType: "Café",
                latitude: 30.2669, longitude: -97.7430,
                vibeTags: ["Minimal", "Fast WiFi", "Window Seats"],
                totalSeats: 10, seatsAvailable: 6,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),

            // ── Hotels ─────────────────────────────────────────────
            Cafe(
                name: "Graduate Austin",
                neighborhood: "The Drag",
                description: "A UT-themed boutique hotel right on Guadalupe with a stunning rooftop bar. Their lobby lounge has power outlets at every seat, blazing WiFi, and a steady flow of cold brew on tap.",
                venueType: "Hotel",
                latitude: 30.2940, longitude: -97.7417,
                vibeTags: ["Rooftop", "Power Outlets", "Fast WiFi"],
                totalSeats: 16, seatsAvailable: 10,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),

            Cafe(
                name: "AT&T Hotel & Conference Center",
                neighborhood: "UT Campus",
                description: "Located on the UT campus itself, this full-service conference hotel has hushed, well-lit lobby seating that rivals any co-working space. Surprisingly open atmosphere for non-guests.",
                venueType: "Hotel",
                latitude: 30.2831, longitude: -97.7398,
                vibeTags: ["On Campus", "Quiet", "Business Friendly"],
                totalSeats: 24, seatsAvailable: 18,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),

            // ── Libraries / Co-working ─────────────────────────────
            Cafe(
                name: "Austin Central Library",
                neighborhood: "Downtown",
                description: "Six floors of stunning, light-drenched workspace inside Austin's flagship public library. Rooftop garden, café, fast WiFi, and a no-judgment policy for long sessions — all for $2.",
                venueType: "Library",
                latitude: 30.2641, longitude: -97.7497,
                vibeTags: ["6 Floors", "Rooftop Garden", "Silent Zone"],
                totalSeats: 40, seatsAvailable: 28,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: true,
                ownerID: "other"
            ),

            // ── Event Venues ───────────────────────────────────────
            Cafe(
                name: "Long Center",
                neighborhood: "Riverside",
                description: "Austin's premier performing arts venue opens its stunning riverside lobby to remote workers between shows. Floor-to-ceiling windows face Lady Bird Lake — hard to find a better view for a work session.",
                venueType: "Event Venue",
                latitude: 30.2588, longitude: -97.7519,
                vibeTags: ["Lake Views", "Spacious", "Unique"],
                totalSeats: 30, seatsAvailable: 30,
                pricePerSession: 2.0, sessionMinutes: 90,
                isParticipating: false,
                ownerID: "other"
            ),
        ]
    }
}
