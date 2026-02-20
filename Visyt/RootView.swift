import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        switch vm.role {
        case .none:
            RoleSelectionView()
        case .user:
            UserTabView()
        case .merchant:
            MerchantTabView()
        }
    }
}

// MARK: - Role Selection

struct RoleSelectionView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("visyt")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accent)
                Text("Work anywhere. Pay less.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 14) {
                RoleButton(title: "Continue as User", subtitle: "Find cafes & check in", systemImage: "person.fill") {
                    vm.role = .user
                    vm.requestLocation()
                }
                RoleButton(title: "Continue as Merchant", subtitle: "Manage your café", systemImage: "building.2.fill") {
                    vm.role = .merchant
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct RoleButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - User Tabs

struct UserTabView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "map.fill") }
            WalletView()
                .tabItem { Label("Wallet", systemImage: "creditcard.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color.accent)
    }
}

// MARK: - Merchant Tabs

struct MerchantTabView: View {
    var body: some View {
        TabView {
            MerchantDashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color.accent)
    }
}
