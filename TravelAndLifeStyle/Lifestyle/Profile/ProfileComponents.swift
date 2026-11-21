//
//  ProfileComponents.swift
//  Lifestyle · Day 5 · pieces of the travel profile setup (Day 5 spec, section 3)
//

import SwiftUI

// MARK: - Save feedback

/// Saving… → Saved, or "Not saved · Retry" when a save didn't go through.
struct SavePill: View {
    let state: SaveState
    var onRetry: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .saving:
                pill(fill: Theme.Colors.savingFill, foreground: Theme.Colors.ink2) {
                    ProgressRing(size: 12, lineWidth: 2)
                    Text("Saving…")
                }
                .accessibilityLabel("Saving")
            case .saved:
                pill(fill: Theme.Colors.mint, foreground: Theme.Colors.green) {
                    SymbolIcon(name: "checkmark", size: 11, weight: .bold)
                    Text("Saved")
                }
                .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
            case .failed:
                Button(action: onRetry) {
                    pill(fill: Theme.Colors.dangerFill, foreground: Theme.Colors.red) {
                        SymbolIcon(name: "exclamationmark.circle", size: 12, weight: .semibold)
                        Text("Not saved · Retry")
                    }
                    .frame(minHeight: Theme.Size.touch)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Not saved. Retry")
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.35), value: state)
        // Announce the result politely, without moving focus.
        .onChange(of: state) { _, new in
            if new == .saved { AccessibilityNotification.Announcement("Saved").post() }
            if new == .failed { AccessibilityNotification.Announcement("Not saved").post() }
        }
    }

    private func pill(fill: Color, foreground: Color, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 5) {
            content()
        }
        .font(Theme.TextStyle.footnoteEmphasis.font)
        .foregroundStyle(foreground)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .frame(minHeight: 28)
        .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .fixedSize()
    }
}

// MARK: - Choices

/// A glass tile with an icon, a title and an optional subtitle, then the choices.
struct PreferenceGroup<Content: View>: View {
    let symbol: String
    let title: String
    var subtitle: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                IconCircle(size: 32) {
                    SymbolIcon(name: symbol, size: 14)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .textStyle(.bodyEmphasis)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

/// Multi-select chips that wrap.
struct PreferenceChips: View {
    struct Option: Identifiable {
        let id: String
        let name: String
    }

    let options: [Option]
    let isSelected: (String) -> Bool
    var onToggle: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                ChoiceChip(title: option.name, isSelected: isSelected(option.id)) {
                    onToggle(option.id)
                }
            }
        }
    }
}

extension PreferenceChips {
    init(_ options: [CatalogOption], selected: [String], onToggle: @escaping (String) -> Void) {
        self.init(options: options.map { Option(id: $0.id, name: $0.name) },
                  isSelected: { selected.contains($0) }, onToggle: onToggle)
    }

    init(_ names: [String], selected: [String], onToggle: @escaping (String) -> Void) {
        self.init(options: names.map { Option(id: $0, name: $0) },
                  isSelected: { selected.contains($0) }, onToggle: onToggle)
    }
}

// MARK: - Traveler

/// A detail from the customer record: shown, not editable.
struct LockedRow<Icon: View>: View {
    let label: String
    let value: String
    var showsDivider = true
    @ViewBuilder var icon: Icon

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(fill: Theme.Colors.lockedFill, foreground: Theme.Colors.ink2) {
                icon
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Text(value)
                    .textStyle(.subheadEmphasis)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            SymbolIcon(name: "lock", size: 14)
                .foregroundStyle(Theme.Colors.muted)
        }
        .frame(minHeight: 56)
        .overlay(alignment: .top) {
            if showsDivider { Hairline() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value), can’t be changed here")
    }
}

/// Name, address and date of birth from the record, with the contact details.
struct LockedDetailsCard: View {
    let record: ProfileSampleData.Customer.Record

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("From your profile")
                    .textStyle(.bodyEmphasis)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Text("Can’t be changed here")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .frame(minHeight: 36)
            LockedRow(label: "Name", value: record.name) { SymbolIcon(name: "person", size: 15) }
            LockedRow(label: "Address", value: record.address) { Glyph(shape: PinShape(), size: 18) }
            LockedRow(label: "Date of birth", value: record.dateOfBirthText) { SymbolIcon(name: "calendar", size: 15) }
            LockedRow(label: "Email", value: record.email) { SymbolIcon(name: "envelope", size: 14) }
            LockedRow(label: "Phone", value: record.phone) { SymbolIcon(name: "iphone", size: 15) }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .cardSurface()
    }
}

/// A traveler document. While typing, the characters show so they can be
/// checked; once saved, only the last digits do.
struct DocumentFieldView: View {
    let field: DocumentField
    @Bindable var model: ProfileModel
    @FocusState private var isFocused: Bool

    var body: some View {
        let stored = model.storedDisplay(field)
        let error = model.documentErrors[field]
        let state = model.documentState(field)
        let draft = model.drafts[field] ?? ""
        // The saved value shows until the customer starts replacing it.
        let showsStored = stored != nil && draft.isEmpty && !isFocused

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(field.label)
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
                if state != .idle {
                    SavePill(state: state) { model.retryDocument(field) }
                        .scaleEffect(0.86, anchor: .trailing)
                        .frame(height: 18)
                }
            }

            TextField(showsStored ? "" : field.placeholder, text: Binding(
                get: { model.drafts[field] ?? "" },
                set: { value in
                    model.drafts[field] = value.isEmpty ? nil : value
                    model.clearDocumentError(field)
                }))
                .focused($isFocused)
                .submitLabel(.next)
                .keyboardType(field == .redress ? .numberPad : .asciiCapable)
                .textInputAutocapitalization(field == .country ? .words : .characters)
                .autocorrectionDisabled()
                .font(Theme.TextStyle.body.font)
                .foregroundStyle(Theme.Colors.ink)
                .tint(Theme.Colors.purple2)
                .frame(minHeight: Theme.Size.touch)
                .overlay(alignment: .leading) {
                    if showsStored, let stored {
                        Text(stored)
                            .textStyle(.body)
                            .lineLimit(1)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 12)
                .background(Theme.Colors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(border(error: error, isSaved: stored != nil), lineWidth: Theme.Size.controlBorder)
                }
                .onSubmit { model.commit(field) }
                // Leaving the field saves it.
                .onChange(of: isFocused) { _, focused in
                    if !focused { model.commit(field) }
                }
                .accessibilityLabel(field.label)
                .accessibilityValue(showsStored ? "Saved, \(spoken(stored ?? ""))" : draft)
                .accessibilityHint(error ?? "Optional")

            if let error {
                HStack(spacing: 5) {
                    SymbolIcon(name: "exclamationmark.circle", size: 13)
                        .foregroundStyle(Theme.Colors.red)
                    Text(error)
                        .textStyle(.footnote, color: Theme.Colors.red)
                }
                .accessibilityHidden(true)
            }
        }
    }

    private func border(error: String?, isSaved: Bool) -> Color {
        if error != nil { return Theme.Colors.red.opacity(0.85) }
        return isSaved ? Theme.Colors.green.opacity(0.35) : Theme.Colors.fieldBorder
    }

    /// "•••• •••• 4417" → "ending 4 4 1 7"
    private func spoken(_ display: String) -> String {
        guard field.isNumber else { return display }
        let digits = display.filter { $0.isLetter || $0.isNumber }
        return "ending \(digits.map(String.init).joined(separator: " "))"
    }
}

/// KTN, passport, country and expiry, redress. All optional.
struct TravelDocumentsCard: View {
    let model: ProfileModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Travel documents")
                    .textStyle(.bodyEmphasis)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Text("Optional")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .frame(minHeight: 36)

            DocumentFieldView(field: .ktn, model: model)
                .padding(.vertical, 10)
            Hairline()
            DocumentFieldView(field: .passport, model: model)
                .padding(.vertical, 10)
            Hairline()
            HStack(alignment: .top, spacing: 10) {
                DocumentFieldView(field: .country, model: model)
                DocumentFieldView(field: .expiry, model: model)
            }
            .padding(.vertical, 10)
            Hairline()
            DocumentFieldView(field: .redress, model: model)
                .padding(.vertical, 10)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .cardSurface()
    }
}

// MARK: - Summary

/// One area of the profile: what is saved, or what it will ask.
struct ProfileSummaryCard: View {
    enum Status {
        /// The area's own save state.
        case live
        /// Not reached yet: shows what it collects.
        case upNext
        /// On the Done screen: Saved, or Skipped when nothing was picked.
        case final
    }

    let area: ProfileArea
    let model: ProfileModel
    var status: Status

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                IconCircle(size: 30) {
                    SymbolIcon(name: area.symbol, size: 13)
                }
                Text(area.title)
                    .textStyle(.subheadEmphasis)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                statusView
            }
            .padding(.bottom, 4)

            if status == .upNext {
                Text(model.teaser(area))
                    .textStyle(.footnote, color: Theme.Colors.muted)
            } else {
                ForEach(model.summary(area)) { row in
                    HStack(alignment: .top, spacing: 8) {
                        Text(row.label)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                            .frame(width: 96, alignment: .leading)
                        Text(row.value)
                            .textStyle(.subhead)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentTransition(.opacity)
                    }
                    .padding(.vertical, 3)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: 18)
        .animation(Theme.Motion.select, value: model.preferences)
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .live:
            SavePill(state: model.saveState(area)) { model.retry(area) }
        case .upNext:
            NeutralTag(text: "Up next")
        case .final:
            if model.isEmpty(area) {
                NeutralTag(text: "Skipped")
            } else if model.saveState(area) == .failed {
                SavePill(state: .failed) { model.retry(area) }
            } else {
                SavePill(state: .saved)
            }
        }
    }
}

// MARK: - Action bar

/// Sticky glass bar: a text button, a caption, and the primary button.
struct ProfileActionBar: View {
    let secondaryTitle: String
    var caption: (title: String, detail: String)?
    let primaryTitle: String
    var primaryKind: FilledButtonStyle.Kind = .red
    /// A sparkle after the title: the button leads to Concierge.
    var primaryShowsSparkle = false
    var onSecondary: () -> Void
    var onPrimary: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the caption sits under the buttons.
        let stacksCaption = dynamicTypeSize.isAccessibilitySize

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Button(secondaryTitle, action: onSecondary)
                    .buttonStyle(TextButtonStyle())
                if let caption, !stacksCaption {
                    captionView(caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer(minLength: 0)
                }
                Button(action: onPrimary) {
                    HStack(spacing: 6) {
                        Text(primaryTitle)
                        if primaryShowsSparkle {
                            Glyph.sparkle(16, lineWidth: 2)
                        }
                    }
                }
                    .buttonStyle(FilledButtonStyle(kind: primaryKind, fullWidth: false))
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)
            }
            if let caption, stacksCaption {
                captionView(caption)
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(minHeight: 68)
        .floatingGlass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func captionView(_ caption: (title: String, detail: String)) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(caption.title)
                .textStyle(.footnoteEmphasis, color: Theme.Colors.ink2)
            Text(caption.detail)
                .textStyle(.footnote, color: Theme.Colors.muted)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}

/// Purple text button in a bar: Skip, Opt out, Back to Lifestyle.
struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.headline, color: configuration.isPressed ? Theme.Colors.purplePressed : Theme.Colors.purple)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(minHeight: Theme.Size.primaryButton)
            .contentShape(Rectangle())
    }
}

// MARK: - Toast

/// "Travel profile saved · Fargo Concierge now uses your preferences"
struct ProfileSavedToast: View {
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.Colors.green)
                .frame(width: 28, height: 28)
                .overlay {
                    Glyph(shape: CheckShape(), size: 16, lineWidth: 3)
                        .foregroundStyle(Theme.Colors.white)
                }
            VStack(alignment: .leading, spacing: 0) {
                Text("Travel profile saved")
                    .textStyle(.subheadEmphasis)
                Text("Fargo Concierge now uses your preferences")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frostSurface(radius: 22)
        .accessibilityElement(children: .combine)
        .onAppear {
            AccessibilityNotification.Announcement("Travel profile saved. Fargo Concierge now uses your preferences.").post()
        }
    }
}

#Preview("Profile components") {
    let store = LifestyleStore.preview(profile: ProfileSampleData.sample.afterSetup)
    let model = store.profile
    return ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SavePill(state: .saving)
                SavePill(state: .saved)
                SavePill(state: .failed)
            }
            PreferenceGroup(symbol: "bed.double", title: "Hotel brands", subtitle: "Pick any you like") {
                PreferenceChips(model.catalog.hotelBrands, selected: model.preferences.brands.hotelBrandIds) {
                    model.toggleHotelBrand($0)
                }
            }
            LockedDetailsCard(record: model.record)
            TravelDocumentsCard(model: model)
            ProfileSummaryCard(area: .brands, model: model, status: .final)
            ProfileSummaryCard(area: .dining, model: model, status: .upNext)
            ProfileActionBar(secondaryTitle: "Skip", caption: ("Saves as you go", "Nothing is required"),
                             primaryTitle: "Next: Dining", onSecondary: {}, onPrimary: {})
            ProfileSavedToast()
        }
        .padding(16)
    }
    .background(AmbientBackground())
}
