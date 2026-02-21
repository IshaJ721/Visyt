import SwiftUI
import MapKit

struct DiscoverView: View {
    @EnvironmentObject var vm: AppViewModel

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2900, longitude: -97.7400),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var showRoute = false
    @State private var route: MKRoute?
    @State private var centeredOnUser = false

    var participatingCafes: [Cafe] { vm.cafes.filter { $0.isParticipating } }

    var body: some View {
        ZStack {
            mapView
                .ignoresSafeArea()
        }
        // Persistent draggable bottom sheet
        .sheet(isPresented: .constant(true)) {
            cafeListSheet
                .presentationDetents([.height(90), .medium, .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled()
                .presentationCornerRadius(22)
                .sheet(isPresented: $vm.showCheckIn) {
                    if let cafe = vm.selectedCafe {
                        CheckInView(cafe: cafe)
                    }
                }
        }
        .fullScreenCover(isPresented: $vm.showSession) {
            SessionView()
        }
        .onAppear {
            vm.requestLocation()
        }
        // Center map on first real location fix
        .onChange(of: vm.userLocation) { _, newLoc in
            guard !centeredOnUser, let loc = newLoc else { return }
            centeredOnUser = true
            withAnimation(.easeInOut(duration: 0.8)) {
                position = .region(MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                ))
            }
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $position) {
            UserAnnotation()

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

            if showRoute, let route {
                MapPolyline(route.polyline)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic))
    }

    // MARK: - Bottom Sheet Content

    private var cafeListSheet: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color(.systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)

            // Route preview bar when a cafe is selected
            if let cafe = vm.selectedCafe, sheetDetent != .height(90) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(cafe.name)
                            .font(.subheadline.bold())
                        Text(cafe.neighborhood)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        if showRoute { showRoute = false; route = nil }
                        else { fetchRoute(to: cafe) }
                    } label: {
                        Label(showRoute ? "Hide Route" : "Walking Route",
                              systemImage: showRoute ? "xmark" : "figure.walk")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentLight)
                            .foregroundStyle(Color.accent)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider()
            }

            // Cafe cards list
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
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helpers

    private func centerMap(on cafe: Cafe) {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: cafe.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
            ))
        }
    }

    private func fetchRoute(to cafe: Cafe) {
        let origin: CLLocationCoordinate2D
        if let loc = vm.userLocation {
            origin = loc.coordinate
        } else {
            origin = CLLocationCoordinate2D(latitude: 30.2849, longitude: -97.7341) // UT Austin
        }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: cafe.coordinate))
        request.transportType = .walking
        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                route = response?.routes.first
                showRoute = true
                withAnimation { sheetDetent = .height(90) }  // shrink sheet to reveal route
            }
        }
    }
}

// MARK: - Cafe Pin

struct CafePin: View {
    let isSelected: Bool
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accent : .white)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 15))
                .foregroundStyle(isSelected ? .white : Color.accent)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

// MARK: - Location Card

struct LocationCard: View {
    @EnvironmentObject var vm: AppViewModel
    let cafe: Cafe
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Name + distance
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cafe.name)
                        .font(.headline)
                    Text(cafe.neighborhood)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(vm.distance(to: cafe))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            // Description
            Text(cafe.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Seats + price
            HStack(spacing: 6) {
                Label("\(cafe.seatsAvailable) seats", systemImage: "person.2.fill")
                    .font(.caption.bold())
                    .foregroundStyle(cafe.seatsAvailable > 0 ? Color.accent : .red)
                Spacer()
                Text("$\(Int(cafe.pricePerSession)) / \(cafe.sessionMinutes) min")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accent)
            }

            // Vibe tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(cafe.vibeTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.accentLight)
                            .foregroundStyle(Color.accent)
                            .clipShape(Capsule())
                    }
                }
            }

            // Check in button
            Button {
                vm.selectedCafe = cafe
                vm.showCheckIn = true
            } label: {
                Text("Check In")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(cafe.seatsAvailable > 0 ? Color.accent : Color(.systemFill))
                    .foregroundStyle(cafe.seatsAvailable > 0 ? .white : Color(.secondaryLabel))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            }
            .disabled(cafe.seatsAvailable == 0)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }
}
