import SwiftUI

struct SessionView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var showEndConfirm = false

    var session: Session? { vm.activeSession }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session?.cafeName ?? "")
                        .font(.title3.bold())
                }
                Spacer()
                Image(systemName: "wifi")
                    .foregroundStyle(Color.accent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 24)

            // Timer ring
            ZStack {
                Circle()
                    .stroke(Color.accent.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(timeString(vm.timeRemaining))
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(vm.timeRemaining < 600 ? .red : .primary)
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)
            .padding(.vertical, 32)

            if vm.timeRemaining < 600 {
                Label("Session ending soon!", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                    .padding(.bottom, 16)
            }

            // Wallet credit
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(Color.accent)
                Text("Wallet Credit")
                Spacer()
                Text("$\(vm.walletCredit, specifier: "%.2f")")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    vm.extendSession()
                } label: {
                    Label("Extend +30 min  ($1.00)", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accent.opacity(0.12))
                        .foregroundStyle(Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showEndConfirm = true
                } label: {
                    Text("End Session")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .confirmationDialog("End your session?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End Session", role: .destructive) { vm.endSession() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var timerProgress: CGFloat {
        guard let session = session else { return 0 }
        let total = session.endTime.timeIntervalSince(session.startTime)
        guard total > 0 else { return 0 }
        return CGFloat(vm.timeRemaining / total).clamped(to: 0...1)
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let t = max(0, Int(interval))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
