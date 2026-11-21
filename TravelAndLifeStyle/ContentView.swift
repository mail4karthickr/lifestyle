//
//  ContentView.swift
//  TravelAndLifeStyle
//
//  Stand-in for the retail banking app. Lifestyle opens full screen from the
//  app's Menu, and Close on its landing page comes back to the Menu. The POC
//  starts with Lifestyle already open.
//

import SwiftUI

struct ContentView: View {
    @State private var isLifestyleOpen = true
    @State private var scenario: LifestyleScenario
    /// Kept while the demo options stay the same, so bookings made in this
    /// session are still there after Close and reopen.
    @State private var store: LifestyleStore

    init() {
        LifestyleDemo.applyLaunchProfileOption()
        let scenario = LifestyleScenario.launch
        _scenario = State(initialValue: scenario)
        _store = State(initialValue: LifestyleStore(scenario: scenario))
    }

    var body: some View {
        // Lifestyle takes over the whole scene, like a product page pushed from
        // the Menu, so it gets the same safe areas as any other page of the app.
        ZStack {
            if isLifestyleOpen {
                LifestyleRootView(store: store) {
                    isLifestyleOpen = false
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            } else {
                MenuStandInView(scenario: $scenario, onRestart: restart) {
                    isLifestyleOpen = true
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isLifestyleOpen)
        // The mock services are set up from the options, so a change starts over.
        .onChange(of: scenario) { restart() }
    }

    private func restart() {
        store = LifestyleStore(scenario: scenario)
    }
}

/// Demo-only switches that act on stored data rather than on a scenario.
enum LifestyleDemo {
    enum ProfileOption: String {
        case keep, reset, sample
    }

    private static var didApplyLaunchOption = false

    /// `-lifestyleProfile reset|sample`: clears the saved travel profile (so the
    /// banner comes back) or stores the sample one, once at launch.
    static func applyLaunchProfileOption() {
        guard !didApplyLaunchOption else { return }
        didApplyLaunchOption = true
        let option = UserDefaults.standard.string(forKey: "lifestyleProfile").flatMap(ProfileOption.init(rawValue:)) ?? .keep
        apply(option)
    }

    static func apply(_ option: ProfileOption) {
        let data = ProfileSampleData.sample
        let service = MockPreferencesService()
        switch option {
        case .keep: break
        case .reset: service.reset(ecn: data.customer.ecn)
        case .sample: service.seed(data.afterSetup, ecn: data.customer.ecn)
        }
    }
}

/// Not part of the Lifestyle designs: a stand-in for the retail app's Menu,
/// where Lifestyle is opened from and where Close lands, plus the demo
/// switches for the mock services.
private struct MenuStandInView: View {
    @Binding var scenario: LifestyleScenario
    var onRestart: () -> Void
    var onOpen: () -> Void

    private static let todayOptions: [(label: String, date: Date?)] = [
        ("Today", nil),
        ("Jan 3, 2027 · after Houston", TripCalendar.date("2027-01-03")),
        ("Feb 17, 2027 · after both trips", TripCalendar.date("2027-02-17")),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Lifestyle", systemImage: "suitcase", action: onOpen)
                } footer: {
                    Text("Stand-in for the retail app's Menu. Changing an option below starts the demo over.")
                }

                Section("Demo options") {
                    Picker("Loading", selection: $scenario.loading) {
                        ForEach(LifestyleScenario.Loading.allCases) { loading in
                            Text(loading.label).tag(loading)
                        }
                    }
                    Picker("Rewards balance", selection: $scenario.points) {
                        Text("12,450 pts").tag(Int?.none)
                        Text("52,450 pts · enough for points only").tag(Int?.some(52_450))
                    }
                }

                Section {
                    Picker("Reprice", selection: $scenario.reprice) {
                        ForEach(AspireScenario.Reprice.allCases) { reprice in
                            Text(reprice.label).tag(reprice)
                        }
                    }
                    Picker("Booking", selection: $scenario.booking) {
                        ForEach(AspireScenario.Booking.allCases) { booking in
                            Text(booking.label).tag(booking)
                        }
                    }
                } header: {
                    Text("Day 2 · Hotel booking")
                } footer: {
                    Text("What the mock hotel service answers when the price is rechecked and when the booking is submitted.")
                }

                Section {
                    Picker("Reserving", selection: $scenario.dining) {
                        ForEach(DiningScenario.allCases) { dining in
                            Text(dining.label).tag(dining)
                        }
                    }
                } header: {
                    Text("Day 3 · Reserve a table")
                } footer: {
                    Text("What happens when the table is reserved. Table counts reset when the demo starts over.")
                }

                Section {
                    Picker("Booked at start", selection: $scenario.seed) {
                        ForEach(BookingSeed.allCases) { seed in
                            Text(seed.label).tag(seed)
                        }
                    }
                    Picker("Today is", selection: $scenario.today) {
                        ForEach(Self.todayOptions, id: \.label) { option in
                            Text(option.label).tag(option.date)
                        }
                    }
                } header: {
                    Text("My plans and trips · Day 4")
                } footer: {
                    Text("A trip's tile goes away the day after it ends.")
                }

                Section {
                    Picker("Saving", selection: $scenario.profileSave) {
                        ForEach(ProfileSaveScenario.allCases) { save in
                            Text(save.label).tag(save)
                        }
                    }
                    Button("Reset travel profile", systemImage: "arrow.counterclockwise") {
                        LifestyleDemo.apply(.reset)
                        onRestart()
                    }
                    Button("Use the sample profile", systemImage: "person.text.rectangle") {
                        LifestyleDemo.apply(.sample)
                        onRestart()
                    }
                } header: {
                    Text("Day 5 · Travel profile")
                } footer: {
                    Text("The profile is saved on this device. Reset brings the banner back; the sample profile makes Inspire me personal.")
                }
            }
            .navigationTitle("Menu")
        }
    }
}

#Preview {
    ContentView()
}
