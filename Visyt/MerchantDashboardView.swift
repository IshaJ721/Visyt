import SwiftUI

struct MerchantDashboardView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedCafe: Cafe?

    var merchantCafes: [Cafe] { vm.cafes.filter { $0.ownerID == "merchant1" } }

    var body: some View {
        NavigationStack {
            List {
                if merchantCafes.isEmpty {
                    Text("No locations found.")
                        .foregroundStyle(.secondary)
                } else {
                    Section("Your Locations") {
                        ForEach(merchantCafes) { cafe in
                            NavigationLink(destination: MerchantLocationView(cafe: cafe)) {
                                MerchantCafeRow(cafe: cafe)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct MerchantCafeRow: View {
    @EnvironmentObject var vm: AppViewModel
    let cafe: Cafe

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cafe.name).font(.headline)
                Spacer()
                Circle()
                    .fill(cafe.isParticipating ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(cafe.isParticipating ? "Open" : "Closed")
                    .font(.caption)
                    .foregroundStyle(cafe.isParticipating ? .green : .secondary)
            }
            Text("Today: $\(vm.todayRevenue(for: cafe), specifier: "%.2f")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
            Section("Status") {
                Toggle("Participating", isOn: Binding(
                    get: { liveCafe.isParticipating },
                    set: { _ in vm.toggleParticipating(cafe: liveCafe) }
                ))

                LabeledContent("Today's Revenue") {
                    Text("$\(vm.todayRevenue(for: liveCafe), specifier: "%.2f")")
                        .foregroundStyle(Color.accent)
                        .fontWeight(.semibold)
                }
            }

            Section("Controls") {
                Stepper("Seat Capacity: \(liveCafe.totalSeats)",
                        value: Binding(
                            get: { liveCafe.totalSeats },
                            set: { vm.setSeats($0, for: liveCafe) }
                        ), in: 1...50)

                Stepper("Price: $\(liveCafe.pricePerSession, specifier: "%.0f")",
                        value: Binding(
                            get: { liveCafe.pricePerSession },
                            set: { vm.setPrice($0, for: liveCafe) }
                        ), in: 1...20)

                Stepper("Duration: \(liveCafe.sessionMinutes) min",
                        value: Binding(
                            get: { liveCafe.sessionMinutes },
                            set: { vm.setDuration($0, for: liveCafe) }
                        ), in: 15...240, step: 15)
            }

            Section("Active Sessions (\(sessions.count))") {
                if sessions.isEmpty {
                    Text("No active sessions right now.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        ActiveSessionRow(session: session)
                    }
                }
            }
        }
        .navigationTitle(cafe.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActiveSessionRow: View {
    let session: Session
    @State private var remaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.userName).font(.subheadline.bold())
                Text("Checked in \(session.startTime, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(timeString(remaining))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(remaining < 600 ? .red : Color.accent)
                .fontWeight(.semibold)
        }
        .onReceive(timer) { _ in remaining = session.timeRemaining }
        .onAppear { remaining = session.timeRemaining }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let t = max(0, Int(interval))
        let m = t / 60; let s = t % 60
        return String(format: "%02d:%02d", m, s)
    }
}
