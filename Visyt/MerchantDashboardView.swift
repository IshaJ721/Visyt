import SwiftUI

// MARK: - Dashboard (single shop — goes straight to detail)

struct MerchantDashboardView: View {
    @EnvironmentObject var vm: AppViewModel

    var merchantCafe: Cafe? { vm.cafes.first(where: { $0.ownerID == "merchant1" }) }

    var body: some View {
        NavigationStack {
            if let cafe = merchantCafe {
                MerchantLocationView(cafe: cafe)
            } else {
                ContentUnavailableView(
                    "No Location Found",
                    systemImage: "building.2",
                    description: Text("Reset demo data in Settings to restore.")
                )
                .navigationTitle("Dashboard")
            }
        }
    }
}

// MARK: - Location Detail

struct MerchantLocationView: View {
    @EnvironmentObject var vm: AppViewModel
    let cafe: Cafe

    var liveCafe: Cafe { vm.cafes.first(where: { $0.id == cafe.id }) ?? cafe }
    var sessions: [Session] { vm.activeSessions(for: liveCafe) }

    var body: some View {
        List {
            // Header card
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(liveCafe.name)
                                .font(.title3.bold())
                            Text(liveCafe.neighborhood)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(isOpen: liveCafe.isParticipating)
                    }
                    Text(liveCafe.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding(.vertical, 4)
            }

            Section("Today") {
                LabeledContent("Revenue") {
                    Text("$\(vm.todayRevenue(for: liveCafe), specifier: "%.2f")")
                        .foregroundStyle(Color.accent)
                        .fontWeight(.semibold)
                }
                LabeledContent("Active Sessions") {
                    Text("\(sessions.count)")
                        .fontWeight(.semibold)
                }
            }

            Section("Controls") {
                Toggle(isOn: Binding(
                    get: { liveCafe.isParticipating },
                    set: { _ in vm.toggleParticipating(cafe: liveCafe) }
                )) {
                    Label("Accepting Guests", systemImage: "door.left.hand.open")
                }
                .tint(Color.accent)

                Stepper(
                    "Seat Capacity: \(liveCafe.totalSeats)",
                    value: Binding(
                        get: { liveCafe.totalSeats },
                        set: { vm.setSeats($0, for: liveCafe) }
                    ), in: 1...50
                )

                Stepper(
                    "Price: $\(Int(liveCafe.pricePerSession))",
                    value: Binding(
                        get: { liveCafe.pricePerSession },
                        set: { vm.setPrice($0, for: liveCafe) }
                    ), in: 1...20
                )

                Stepper(
                    "Duration: \(liveCafe.sessionMinutes) min",
                    value: Binding(
                        get: { liveCafe.sessionMinutes },
                        set: { vm.setDuration($0, for: liveCafe) }
                    ), in: 15...240, step: 15
                )
            }

            Section("Active Sessions (\(sessions.count))") {
                if sessions.isEmpty {
                    Text("No active sessions right now.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(sessions) { session in
                        ActiveSessionRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("My Café")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let isOpen: Bool
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isOpen ? Color.green : Color(.systemFill))
                .frame(width: 7, height: 7)
            Text(isOpen ? "Open" : "Closed")
                .font(.caption.bold())
                .foregroundStyle(isOpen ? .green : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background((isOpen ? Color.green : Color(.systemGray5)).opacity(0.15))
        .clipShape(Capsule())
    }
}

struct ActiveSessionRow: View {
    let session: Session
    @State private var remaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.userName)
                    .font(.subheadline.bold())
                Text("Checked in \(session.startTime, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(timeString(remaining))
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundStyle(remaining < 600 ? .red : Color.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background((remaining < 600 ? Color.red : Color.accent).opacity(0.1))
                .clipShape(Capsule())
        }
        .onReceive(timer) { _ in remaining = session.timeRemaining }
        .onAppear { remaining = session.timeRemaining }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let t = max(0, Int(interval))
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
}
