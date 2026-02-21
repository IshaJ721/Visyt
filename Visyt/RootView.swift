import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        switch vm.role {
        case .none:     RoleSelectionView()
        case .user:     UserTabView()
        case .merchant: MerchantTabView()
        }
    }
}

// MARK: - Logo Mark
//
// Concept: WiFi above a generic venue/building — communicates "get connected
// inside any space" (cafes, hotels, event venues, lounges, etc.)

struct LogoMark: View {
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            // Badge
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(
                    LinearGradient(
                        colors: [Color.accentMid, Color.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.accent.opacity(0.45), radius: 18, y: 8)

            VStack(spacing: size * 0.05) {
                // WiFi — connectivity, working from anywhere
                Image(systemName: "wifi")
                    .font(.system(size: size * 0.30, weight: .semibold))
                    .foregroundStyle(.white)

                // Building — any venue, not just cafes
                Image(systemName: "building.2.fill")
                    .font(.system(size: size * 0.28))
                    .foregroundStyle(.white.opacity(0.90))
            }
            .offset(y: size * 0.03)
        }
    }
}

// MARK: - Role Selection

struct RoleSelectionView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 18) {
                LogoMark(size: 88)

                VStack(spacing: 6) {
                    Text("visyt")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(Color.accent)

                    Text("shared space, reimagined")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .kerning(2.0)
                        .textCase(.uppercase)
                }
            }

            Spacer()

            VStack(spacing: 14) {
                RoleButton(
                    title: "Find a Space",
                    subtitle: "Cafes, hotels, venues & more",
                    systemImage: "person.fill"
                ) {
                    vm.role = .user
                    vm.requestLocation()
                }

                RoleButton(
                    title: "I'm a Venue Partner",
                    subtitle: "Manage your space & sessions",
                    systemImage: "building.2.fill"
                ) {
                    vm.role = .merchant
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 56)
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
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentLight)
                        .frame(width: 40, height: 40)
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        }
    }
}

// MARK: - Tabs

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
