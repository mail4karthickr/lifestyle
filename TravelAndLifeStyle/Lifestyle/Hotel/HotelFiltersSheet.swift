//
//  HotelFiltersSheet.swift
//  Lifestyle · filters and sort for hotel results
//
//  Sort, price range, guest rating, brand, amenities, distance from and
//  accessibility. Changes apply as they are made; the footer shows the count.
//

import SwiftUI

struct HotelFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: HotelFlowModel
    /// The group the customer tapped; the sheet opens scrolled to it.
    var focus: FilterSection = .all

    var body: some View {
        let options = model.filterOptions
        let count = model.matchCount(for: model.filters)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Text("Filters")
                            .textStyle(.title2)
                            .accessibilityAddTraits(.isHeader)
                        Spacer(minLength: 0)
                        Button("Clear all") {
                            withAnimation(Theme.Motion.select) {
                                model.filters = HotelFilters()
                                model.sort = .recommended
                            }
                        }
                        .buttonStyle(.plain)
                        .textStyle(.subheadEmphasis, color: Theme.Colors.purple)
                        .frame(minHeight: Theme.Size.touch)
                    }

                    group("Sort by", section: .all) {
                        SegmentedControl(options: HotelSort.allCases.map { .init(value: $0, label: $0.rawValue) },
                                         selection: model.sort, height: 44) { model.sort = $0 }
                    }

                    group("Price per night", section: .price) {
                        let range = model.filters.price ?? options.priceRange
                        VStack(spacing: 2) {
                            RangeSlider(range: Binding(
                                get: { range },
                                set: { model.filters.price = $0 == options.priceRange ? nil : $0 }),
                                bounds: options.priceRange, step: 10)
                            HStack {
                                Text(Decimal(range.lowerBound).usdWhole)
                                Spacer(minLength: 8)
                                Text("\(Decimal(range.upperBound).usdWhole) a night")
                            }
                            .textStyle(.footnoteEmphasis)
                        }
                    }

                    group("Guest rating", section: .rating) {
                        chips(options.ratings) { option in
                            model.filters.minimumRating == Self.rating(option)
                        } toggle: { option in
                            model.filters.minimumRating = Self.rating(option)
                        }
                    }

                    group("Brand", section: .brand) {
                        chips(options.brands) { model.filters.brands.contains($0) } toggle: {
                            model.filters.brands.formSymmetricDifference([$0])
                        }
                    }

                    group("Amenities", section: .amenities) {
                        chips(options.amenities) { model.filters.amenities.contains($0) } toggle: {
                            model.filters.amenities.formSymmetricDifference([$0])
                        }
                    }

                    group("Distance from", section: .distance) {
                        chips(options.distanceFrom) { model.filters.distanceFrom == $0 } toggle: {
                            model.filters.distanceFrom = $0
                        }
                    }

                    group("Accessibility", section: .accessibility) {
                        chips(options.accessibility) { model.filters.accessibility.contains($0) } toggle: {
                            model.filters.accessibility.formSymmetricDifference([$0])
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 26)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                if focus != .all { proxy.scrollTo(focus, anchor: .top) }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ActionBar(buttonTitle: count == 1 ? "Show 1 hotel" : "Show \(count) hotels", action: { dismiss() }) {
                Text(count == 1 ? "1 hotel matches" : "\(count) hotels match")
                    .textStyle(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground {
            Rectangle()
                .fill(.regularMaterial)
                .overlay(Theme.Colors.sheetFill)
        }
    }

    /// "4.5+" → 4.5; "Any" → nil.
    private static func rating(_ option: String) -> Double? {
        Double(option.trimmingCharacters(in: CharacterSet(charactersIn: "+")))
    }

    private func group(_ title: String, section: FilterSection, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .textStyle(.bodyEmphasis)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .id(section)
    }

    private func chips(_ options: [String], isSelected: @escaping (String) -> Bool,
                       toggle: @escaping (String) -> Void) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                ChoiceChip(title: option, isSelected: isSelected(option)) { toggle(option) }
            }
        }
    }
}

/// Two-thumb slider for a price range.
struct RangeSlider: View {
    @Binding var range: ClosedRange<Int>
    let bounds: ClosedRange<Int>
    var step = 1

    private let thumb: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let track = max(geo.size.width - thumb, 1)
            let low = position(range.lowerBound, track: track)
            let high = position(range.upperBound, track: track)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.sliderTrack)
                    .frame(height: 4)
                Capsule()
                    .fill(Theme.Colors.purple2)
                    .frame(width: max(high - low, 0), height: 4)
                    .offset(x: low + thumb / 2)
                handle(at: low, label: "Lowest price", value: range.lowerBound) { x in
                    let value = min(self.value(at: x, track: track), range.upperBound - step)
                    range = max(value, bounds.lowerBound)...range.upperBound
                } adjust: { delta in
                    let value = min(max(range.lowerBound + delta * step, bounds.lowerBound), range.upperBound - step)
                    range = value...range.upperBound
                }
                handle(at: high, label: "Highest price", value: range.upperBound) { x in
                    let value = max(self.value(at: x, track: track), range.lowerBound + step)
                    range = range.lowerBound...min(value, bounds.upperBound)
                } adjust: { delta in
                    let value = max(min(range.upperBound + delta * step, bounds.upperBound), range.lowerBound + step)
                    range = range.lowerBound...value
                }
            }
            .frame(height: 32)
            .coordinateSpace(.named("rangeSlider"))
        }
        .frame(height: 32)
    }

    private func position(_ value: Int, track: CGFloat) -> CGFloat {
        let span = CGFloat(max(bounds.upperBound - bounds.lowerBound, 1))
        return CGFloat(value - bounds.lowerBound) / span * track
    }

    private func value(at x: CGFloat, track: CGFloat) -> Int {
        let fraction = min(max(x / track, 0), 1)
        let raw = Double(bounds.lowerBound) + Double(fraction) * Double(bounds.upperBound - bounds.lowerBound)
        return Int((raw / Double(step)).rounded()) * step
    }

    private func handle(at x: CGFloat, label: String, value: Int,
                        onDrag: @escaping (CGFloat) -> Void, adjust: @escaping (Int) -> Void) -> some View {
        Circle()
            .fill(Theme.Colors.white)
            .overlay { Circle().strokeBorder(Theme.Colors.purple2, lineWidth: 2) }
            .frame(width: thumb, height: thumb)
            .frame(width: Theme.Size.touch, height: Theme.Size.touch)
            .contentShape(Rectangle())
            .offset(x: x - (Theme.Size.touch - thumb) / 2)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("rangeSlider")).onChanged { drag in
                onDrag(drag.location.x - thumb / 2)
            })
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(Decimal(value).usdWhole)
            .accessibilityAdjustableAction { direction in
                adjust(direction == .increment ? 1 : -1)
            }
    }
}

#Preview("Filters") {
    let store = LifestyleStore.preview()
    return Color.clear.sheet(isPresented: .constant(true)) {
        HotelFiltersSheet(model: store.hotel)
            .task { await store.hotel.loadResults() }
    }
}
