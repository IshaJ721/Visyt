import SwiftUI
import PassKit

struct CheckInView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) var dismiss
    let cafe: Cafe

    @State private var isPaying = false
    @State private var paymentDone = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accent)
                        .padding(.top, 24)
                    Text(cafe.name)
                        .font(.title2.bold())
                    Text(cafe.neighborhood)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)

                // Summary card
                VStack(spacing: 0) {
                    InfoRow(label: "Duration", value: "\(cafe.sessionMinutes) minutes")
                    Divider().padding(.horizontal)
                    InfoRow(label: "Seats available", value: "\(cafe.seatsAvailable)")
                    Divider().padding(.horizontal)
                    InfoRow(label: "Cashback earned", value: "$0.50", valueColor: .green)
                    Divider().padding(.horizontal)
                    InfoRow(label: "Total", value: String(format: "$%.2f", cafe.pricePerSession), valueColor: Color.accent)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 14) {
                    if paymentDone {
                        Label("Payment confirmed!", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                    } else {
                        // Apple Pay styled button
                        ApplePayButton {
                            simulatePayment()
                        }
                        .frame(height: 50)
                        .padding(.horizontal, 20)
                        .opacity(isPaying ? 0.5 : 1)
                        .disabled(isPaying)
                    }

                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Confirm Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func simulatePayment() {
        isPaying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            paymentDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                vm.checkIn(cafe: cafe)
            }
        }
    }
}

// MARK: - InfoRow

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Apple Pay Button wrapper

struct ApplePayButton: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}
