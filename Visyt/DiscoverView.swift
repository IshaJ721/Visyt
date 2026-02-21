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
    @State private var centeredOnUser = false

    // Panel state
    @State private var panelHeight: CGFloat = 280
    @State private var dragOffset: CGFloat = 0
    private let snapHeights: [CGFloat] = [90, 280, 560]
    private let panelTotalHeight: CGFloat = 640

    // Route
    @State private var showRoute = false
    @State private var route: MKRoute?

    var participatingCafes: [Cafe] { vm.cafes.filter { $0.isParticipating } }

    // How far down to offset the panel so that only `visibleHeight` pts show above the bottom
    private var panelOffset: CGFloat {
        let visible = (panelHeight + dragOffset).clamped(to: snapHeights[0]...snapHeights.last!)
        return panelTotalHeight - visible
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapView
                .ignoresSafeArea()

            draggablePanel
        }
        .sheet(isPresented: $vm.showCheckIn) {
            if let cafe = vm.selectedCafe {
                CheckInView(cafe: cafe)
            }
        }
        .fullScreenCover(isPresented: $vm.showSession) {
            SessionView()
        }
        .onAppear { vm.requestLocation() }
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
                    CafePin(isSelected: vm.selectedCafe?.id == cafe.id, icon: cafe.pinIcon)
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

    // MARK: - Draggable Panel

    private var draggablePanel: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color(.systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)

            // Route preview bar (visible when cafe selected and panel not fully open)
            if let cafe = vm.selectedCafe {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(cafe.name).font(.subheadline.bold())
                        Text(cafe.neighborhood).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        if showRoute { showRoute = false; route = nil }
                        else { fetchRoute(to: cafe) }
                    } label: {
                        Label(showRoute ? "Hide" : "Walking Route",
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
                .padding(.bottom, 10)

                Divider()
            }

            // Cafe list
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

            Spacer(minLength: 0)
        }
        .frame(height: panelTotalHeight)
        .frame(maxWidth: .infinity)
        .background(
            Color(.systemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.10), radius: 16, y: -4)
        )
        .offset(y: panelOffset)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    dragOffset = -value.translation.height
                }
                .onEnded { value in
                    let projected = panelHeight - value.predictedEndTranslation.height
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        panelHeight = snap(projected)
                        dragOffset = 0
                    }
                }
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: panelHeight)
    }

    // MARK: - Helpers

    private func snap(_ height: CGFloat) -> CGFloat {
        snapHeights.min(by: { abs($0 - height) < abs($1 - height) }) ?? 280
    }

    private func centerMap(on cafe: Cafe) {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: cafe.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
            ))
        }
    }

    private func fetchRoute(to cafe: Cafe) {
        let origin = vm.userLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 30.2849, longitude: -97.7341)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: cafe.coordinate))
        request.transportType = .walking
        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                route = response?.routes.first
                showRoute = true
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    panelHeight = snapHeights[0]   // collapse to peek so route is visible
                }
            }
        }
    }
}

// MARK: - Cafe Pin

struct CafePin: View {
    let isSelected: Bool
    var icon: String = "cup.and.saucer.fill"

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accent : .white)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .white : Color.accent)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

// MARK: - Venue Type Badge

struct VenueTypeBadge: View {
    let type: String

    private var icon: String {
        switch type {
        case "Hotel":       return "bed.double.fill"
        case "Event Venue": return "theatermasks.fill"
        case "Library":     return "books.vertical.fill"
        default:            return "cup.and.saucer.fill"
        }
    }

    var body: some View {
        Label(type, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.accent)
    }
}

// MARK: - Location Card

struct LocationCard: View {
    @EnvironmentObject var vm: AppViewModel
    let cafe: Cafe
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cafe.name).font(.headline)
                    HStack(spacing: 6) {
                        Text(cafe.neighborhood).font(.caption).foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary).font(.caption)
                        VenueTypeBadge(type: cafe.venueType)
                    }
                }
                Spacer()
                Text(vm.distance(to: cafe))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(cafe.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Label("\(cafe.seatsAvailable) seats", systemImage: "person.2.fill")
                    .font(.caption.bold())
                    .foregroundStyle(cafe.seatsAvailable > 0 ? Color.accent : .red)
                Spacer()
                Text("$\(Int(cafe.pricePerSession)) / \(cafe.sessionMinutes) min")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accent)
            }

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
