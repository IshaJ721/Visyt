import SwiftUI
import MapKit

struct DiscoverView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var showRoute = false
    @State private var route: MKRoute?

    var participatingCafes: [Cafe] { vm.cafes.filter { $0.isParticipating } }

    var body: some View {
        ZStack(alignment: .bottom) {
            map
            bottomSheet
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $vm.showCheckIn) {
            if let cafe = vm.selectedCafe {
                CheckInView(cafe: cafe)
            }
        }
        .fullScreenCover(isPresented: $vm.showSession) {
            SessionView()
        }
        .onAppear { vm.requestLocation() }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $position) {
            // User location
            UserAnnotation()

            // Cafe pins
            ForEach(participatingCafes) { cafe in
                Annotation(cafe.name, coordinate: cafe.coordinate) {
                    CafePin(isSelected: vm.selectedCafe?.id == cafe.id)
                        .onTapGesture {
                            withAnimation { vm.selectedCafe = cafe }
                            centerMap(on: cafe)
                            route = nil
                            showRoute = false
                        }
                }
            }

            // Route overlay
            if showRoute, let route {
                MapPolyline(route.polyline)
                    .stroke(Color.accent, lineWidth: 4)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .frame(height: UIScreen.main.bounds.height * 0.55)
    }

    // MARK: - Bottom Sheet

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            // Route preview bar (shown when cafe selected)
            if let cafe = vm.selectedCafe {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cafe.name).font(.headline)
                        Text(cafe.neighborhood).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(showRoute ? "Hide Route" : "Preview Route") {
                        if showRoute {
                            showRoute = false
                            route = nil
                        } else {
                            fetchRoute(to: cafe)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(Color.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
            }

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(participatingCafes) { cafe in
                        LocationCard(cafe: cafe, isSelected: vm.selectedCafe?.id == cafe.id)
                            .onTapGesture {
                                withAnimation { vm.selectedCafe = cafe }
                                centerMap(on: cafe)
                            }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        .frame(height: UIScreen.main.bounds.height * 0.48)
    }

    // MARK: - Helpers

    private func centerMap(on cafe: Cafe) {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: cafe.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    private func fetchRoute(to cafe: Cafe) {
        guard let userLoc = vm.userLocation else {
            showRoute = true
            return
        }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: cafe.coordinate))
        request.transportType = .walking
        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                route = response?.routes.first
                showRoute = true
            }
        }
    }
}

// MARK: - CafePin

struct CafePin: View {
    let isSelected: Bool
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accent : Color.white)
                .frame(width: 32, height: 32)
                .shadow(radius: 3)
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .white : Color.accent)
        }
    }
}

// MARK: - LocationCard

struct LocationCard: View {
    @EnvironmentObject var vm: AppViewModel
    let cafe: Cafe
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cafe.name).font(.headline)
                    Text(cafe.neighborhood).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(vm.distance(to: cafe))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Label("\(cafe.seatsAvailable) seats", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(cafe.seatsAvailable > 0 ? .green : .red)
                Spacer()
                Text("$\(cafe.pricePerSession, specifier: "%.0f") / \(cafe.sessionMinutes) min")
                    .font(.caption)
                    .foregroundStyle(Color.accent)
                    .fontWeight(.semibold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(cafe.vibeTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accent.opacity(0.1))
                            .foregroundStyle(Color.accent)
                            .clipShape(Capsule())
                    }
                }
            }

            Button {
                vm.selectedCafe = cafe
                vm.showCheckIn = true
            } label: {
                Text("Check In")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(cafe.seatsAvailable > 0 ? Color.accent : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(cafe.seatsAvailable == 0)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
