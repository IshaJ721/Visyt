import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Current Role", value: vm.role.displayName)
                    Button("Switch Role") {
                        vm.role = .none
                    }
                    .foregroundStyle(Color.accent)
                }

                Section("Session History") {
                    if vm.sessionHistory.isEmpty {
                        Text("No completed sessions.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.sessionHistory.reversed()) { session in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.cafeName).font(.subheadline.bold())
                                Text(session.startTime, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Developer") {
                    Button("Reset Demo Data", role: .destructive) {
                        showResetConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset all demo data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { vm.resetDemoData() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
