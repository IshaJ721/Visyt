import SwiftUI

struct WalletView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("$\(vm.walletCredit, specifier: "%.2f")")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.accent)
                            Text("Available Credit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }

                Section("Transaction History") {
                    if vm.transactions.isEmpty {
                        Text("No transactions yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.transactions.reversed()) { tx in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.description).font(.subheadline)
                                    Text(tx.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(tx.amount >= 0 ? "+" : "")$\(abs(tx.amount), specifier: "%.2f")")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(tx.amount >= 0 ? .green : .primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wallet")
        }
    }
}
