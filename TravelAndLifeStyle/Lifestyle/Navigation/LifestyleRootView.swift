//
//  LifestyleRootView.swift
//  Lifestyle · entry point
//
//  Opens full screen from the retail app. Navigation is a standard
//  NavigationStack with standard toolbars, so iPhone Duo can move the controls
//  to its side bar.
//

import SwiftUI

struct LifestyleRootView: View {
    @State private var store: LifestyleStore
    @State private var sceneInsets = EdgeInsets()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let onClose: () -> Void

    init(store: LifestyleStore = LifestyleStore(), onClose: @escaping () -> Void = {}) {
        _store = State(initialValue: store)
        self.onClose = onClose
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack(path: $store.path) {
            LandingView(onClose: onClose)
                .navigationDestination(for: LifestyleRoute.self) { route in
                    switch route {
                    case .concierge:
                        ConciergeView()
                    case .hotelSearch:
                        HotelSearchView()
                    case .hotelResults:
                        HotelResultsView()
                    case .hotelDetails:
                        HotelDetailsView()
                    case .hotelPhotos:
                        HotelPhotosView()
                    case .hotelRooms:
                        HotelRoomsView()
                    case .hotelCheckout:
                        HotelCheckoutView()
                    case .hotelReview:
                        HotelReviewView()
                    case .hotelConfirmed:
                        HotelConfirmationView()
                    case .restaurant:
                        RestaurantView()
                    case .diningTable:
                        DiningTableView()
                    case .diningDetails:
                        DiningDetailsView()
                    case .diningDeposit:
                        DiningDepositView()
                    case .diningReview:
                        DiningReviewView()
                    case .diningConfirmed:
                        DiningConfirmationView()
                    case .itinerary(let bookingId):
                        ItineraryView(bookingId: bookingId)
                    case .bookingDetails(let ref):
                        BookingDetailsView(ref: ref)
                    case .profileIntro:
                        ProfileIntroView()
                    case .profileArea(let area):
                        ProfileAreaView(area: area)
                    case .profileDone:
                        ProfileDoneView()
                    }
                }
        }
        // The safe area before any bars are added: where a top bar starts.
        .environment(\.sceneSafeAreaInsets, sceneInsets)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.safeAreaInsets, initial: true) { _, insets in
                        sceneInsets = insets
                    }
            }
        }
        .environment(store)
        .tint(Theme.Colors.ink)
        .preferredColorScheme(.light)
        // iPhone Duo: the pose decides a few things the size class can't.
        .onHingeChange { old, new in
            store.hingeChanged(from: old.hinge?.status, to: new.hinge?.status)
        }
        // Opening the device is also when the layout goes from one column to two.
        .onChange(of: horizontalSizeClass) { old, new in
            if old == .compact, new == .regular, store.hingeStatus != nil { store.deviceOpened() }
        }
        .task { await startUp() }
    }
}

private extension LifestyleRootView {
    /// The landing sections load on their own; a demo start doesn't wait for them.
    func startUp() async {
        let store = store
        if let pose = DemoPose.launch { store.show(pose) }
        async let sections: Void = store.loadIfNeeded()
        if let start = DemoStart.launch, !store.hasStartedDemo {
            store.hasStartedDemo = true
            await store.start(at: start)
        }
        await sections
    }
}

extension EnvironmentValues {
    /// Safe-area insets of the scene, outside the navigation stack and its bars.
    @Entry var sceneSafeAreaInsets = EdgeInsets()
}
