//
//  ConciergeComponents.swift
//  Lifestyle · building blocks of the Concierge chat
//

import SwiftUI

// MARK: - Start

/// "Inspire me" image card. `width` is nil when a grid sizes it.
struct InspireCardView: View {
    let card: ConciergeContent.InspireCard
    var width: CGFloat?
    var imageHeight: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                CardImage(name: card.imageName, height: imageHeight)
                Text(card.prompt)
                    .textStyle(.subheadEmphasis)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width)
            .cardSurface()
        }
        .buttonStyle(PressableStyle())
    }
}

/// Right-aligned outlined prompt, in the retail app's style.
struct PromptChip: View {
    let title: String
    var showsSparkle = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if showsSparkle {
                    Glyph.sparkle(18)
                        .foregroundStyle(Theme.Colors.purple)
                }
                Text(title)
                    .textStyle(.body)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .frame(minHeight: Theme.Size.touch)
            .background(Theme.Colors.promptChipFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.Colors.ink2, lineWidth: Theme.Size.controlBorder)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}

/// "Fargo Concierge is an AI assistant, not a real person…"
struct DisclosureCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            SymbolIcon(name: "info.circle", size: 16)
                .foregroundStyle(Theme.Colors.ink2)
                .frame(width: 18, height: 18)
            Text(text)
                .textStyle(.footnote, color: Theme.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .cardSurface(radius: Theme.Radius.note)
        .accessibilityElement(children: .combine)
    }
}

/// Glass composer: "Start chatting" and a purple outlined mic.
struct ComposerBar: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Start chatting", text: $text, prompt: Text("Start chatting").foregroundStyle(Theme.Colors.muted))
                .font(Theme.TextStyle.body.font)
                .foregroundStyle(Theme.Colors.ink)
                .tint(Theme.Colors.purple2)
                .submitLabel(.send)
                .onSubmit(onSubmit)
                .frame(minHeight: Theme.Size.touch)
                .accessibilityLabel("Message Fargo Concierge")

            // Voice input is not part of the POC.
            Button {} label: {
                SymbolIcon(name: "mic", size: 18)
                    .foregroundStyle(Theme.Colors.purple)
                    .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                    .overlay { Circle().strokeBorder(Theme.Colors.purple, lineWidth: 2) }
                    .contentShape(Circle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Speak")
        }
        .padding(.leading, 18)
        .padding(.trailing, 6)
        .frame(minHeight: Theme.Size.searchBox)
        .floatingGlass()
    }
}

// MARK: - Bubbles

/// The customer's message: purple with white text.
struct UserBubble: View {
    let text: String
    var maxWidth: CGFloat = 290

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: Theme.Radius.bubble, bottomLeading: Theme.Radius.bubble,
            bottomTrailing: Theme.Radius.bubbleTail, topTrailing: Theme.Radius.bubble), style: .continuous)
    }

    var body: some View {
        Text(text)
            .textStyle(.body, color: Theme.Colors.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background {
                shape.fill(Theme.Colors.purple)
                    .shadow(color: Theme.Colors.bubbleShadow, radius: 8, x: 0, y: 6)
            }
            .frame(maxWidth: maxWidth, alignment: .trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("You said: \(text)")
    }
}

/// Fargo Concierge's message: glass, with the Fargo icon as its avatar.
struct ConciergeBubble<Content: View>: View {
    var maxWidth: CGFloat = 300
    /// The avatar animates while a reply is on its way.
    var isTyping = false
    @ViewBuilder var content: Content

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: Theme.Radius.bubble, bottomLeading: Theme.Radius.bubbleTail,
            bottomTrailing: Theme.Radius.bubble, topTrailing: Theme.Radius.bubble), style: .continuous)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            FargoIcon(size: Theme.Size.avatar, isAnimated: isTyping)
            content
                .textStyle(.body)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .cardSurface(in: shape)
                .frame(maxWidth: maxWidth, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .riseIn()
    }
}

extension ConciergeBubble where Content == Text {
    init(_ text: String, maxWidth: CGFloat = 300) {
        self.init(maxWidth: maxWidth) {
            Text(text)
        }
    }
}

// MARK: - Chips

/// Selectable chip. Selected is purple-tinted with a check.
struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    SymbolIcon(name: "checkmark", size: 11, weight: .bold)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(title)
                    .textStyle(.subheadEmphasis, color: isSelected ? Theme.Colors.purple : Theme.Colors.ink)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Theme.Colors.purple : Theme.Colors.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: Theme.Size.touch)
            .background(isSelected ? Theme.Colors.chipSelectedFill : Theme.Colors.chipFill, in: Capsule())
            .overlay {
                Capsule().strokeBorder(isSelected ? Theme.Colors.purple2 : Theme.Colors.chipBorder,
                                       lineWidth: Theme.Size.controlBorder)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .animation(Theme.Motion.select, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// The dates chip: shows the stay and opens the date picker.
struct DatesChip: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                SymbolIcon(name: "calendar", size: 13, weight: .semibold)
                Text(title)
                    .textStyle(.subheadEmphasis, color: Theme.Colors.purple)
                    .lineLimit(1)
                SymbolIcon(name: "chevron.down", size: 10, weight: .bold)
            }
            .foregroundStyle(Theme.Colors.purple)
            .padding(.leading, 14)
            .padding(.trailing, 12)
            .frame(minHeight: Theme.Size.touch)
            .background(Theme.Colors.chipSelectedFill, in: Capsule())
            .overlay { Capsule().strokeBorder(Theme.Colors.purple2, lineWidth: Theme.Size.controlBorder) }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Dates, \(title)")
        .accessibilityHint("Changes the dates")
    }
}

/// Check-in and check-out for the stay Fargo Concierge is planning.
struct ConciergeDatesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let model: ConciergeModel
    @State private var checkIn: Date
    @State private var checkOut: Date

    init(model: ConciergeModel) {
        self.model = model
        _checkIn = State(initialValue: model.checkIn)
        _checkOut = State(initialValue: model.checkOut)
    }

    private var today: Date { TripCalendar.today() }
    private var nights: Int { TripCalendar.nights(checkIn, checkOut) }

    /// Checkout: from the night after check-in, up to the longest stay.
    private var checkOutRange: ClosedRange<Date> {
        ClosedRange(uncheckedBounds: (TripCalendar.adding(days: 1, to: checkIn),
                                      TripCalendar.adding(days: ConciergeModel.maxNights, to: checkIn)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 0) {
                        DatePicker(selection: $checkIn, in: today..., displayedComponents: .date) {
                            label("Check in", symbol: "calendar")
                        }
                        .frame(minHeight: 56)
                        Hairline()
                        DatePicker(selection: $checkOut, in: checkOutRange, displayedComponents: .date) {
                            label("Check out", symbol: "calendar.badge.checkmark")
                        }
                        .frame(minHeight: 56)
                    }
                    .padding(.horizontal, 14)
                    .cardSurface()
                    .tint(Theme.Colors.purple2)

                    HStack(spacing: 10) {
                        IconCircle {
                            SymbolIcon(name: "moon.stars", size: 15)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(TripCalendar.range(checkIn, checkOut))
                                .textStyle(.subheadEmphasis)
                            Text(nights == 1 ? "1 night" : "\(nights) nights")
                                .textStyle(.footnote, color: Theme.Colors.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .cardSurface()
                    .accessibilityElement(children: .combine)

                    InfoNote(text: "Your hotel pick opens with these dates. The chef’s table dinner is on \(DiningSampleData.sample.setup.dayText) only.")

                    Button("Use these dates") {
                        model.setDates(checkIn: checkIn, checkOut: checkOut)
                        dismiss()
                    }
                    .buttonStyle(FilledButtonStyle())
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .background { AmbientBackground() }
            .navigationTitle("Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
        // Trip dates are calendar days in UTC; the pickers must read them the same way,
        // and show them as the rest of the app does ("Dec 30, 2026").
        .environment(\.calendar, TripCalendar.calendar)
        .environment(\.timeZone, TripCalendar.calendar.timeZone)
        .environment(\.locale, .enUS)
        .presentationDetents([.medium, .large])
        // Moving check-in keeps checkout after it, and within the longest stay.
        .onChange(of: checkIn) { _, newValue in
            checkIn = TripCalendar.calendar.startOfDay(for: newValue)
            let range = checkOutRange
            if checkOut.isOnOrBefore(checkIn) {
                checkOut = range.lowerBound
            } else if range.upperBound.isOnOrBefore(checkOut) {
                checkOut = range.upperBound
            }
        }
        .onChange(of: checkOut) { _, newValue in
            checkOut = TripCalendar.calendar.startOfDay(for: newValue)
        }
    }

    private func label(_ title: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            IconCircle {
                SymbolIcon(name: symbol, size: 15)
            }
            Text(title)
                .textStyle(.subheadEmphasis)
        }
    }
}

/// Wraps chips onto as many rows as they need.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: ProposedViewSize(width: min(result.sizes[index].width, bounds.width), height: nil))
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint], sizes: [CGSize]) {
        var origins: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            sizes.append(size)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: min(maxX, width), height: y + rowHeight), origins, sizes)
    }
}

// MARK: - Follow-ups

/// "What matters most? Pick any." Dates, budget (single), vibe and dining (multi).
struct FollowUpCard: View {
    @Bindable var model: ConciergeModel

    var body: some View {
        if let followUps = model.followUps {
            VStack(alignment: .leading, spacing: 10) {
                Text(followUps.title)
                    .textStyle(.bodyEmphasis)

                group("Dates") {
                    DatesChip(title: model.datesText) { model.isChoosingDates = true }
                }
                group("Budget a night") {
                    ForEach(followUps.budgetPerNight.options, id: \.self) { option in
                        ChoiceChip(title: option, isSelected: model.budget == option) {
                            model.budget = option
                        }
                    }
                }
                group("Vibe") {
                    ForEach(followUps.vibe.options, id: \.self) { option in
                        ChoiceChip(title: option, isSelected: model.vibes.contains(option)) {
                            model.toggleVibe(option)
                        }
                    }
                }
                group("Dining") {
                    ForEach(followUps.dining.options, id: \.self) { option in
                        ChoiceChip(title: option, isSelected: model.dining.contains(option)) {
                            model.toggleDining(option)
                        }
                    }
                }

                Button(followUps.cta) { model.showPicks() }
                    .buttonStyle(FilledButtonStyle())
                    .padding(.top, 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(radius: Theme.Radius.groupCard)
            .riseIn(order: 1)
        }
    }

    private func group(_ label: String, @ViewBuilder chips: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
            FlowLayout(spacing: 8) {
                chips()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

/// Collapsed follow-ups once picks are shown, with a way back.
struct AnswersSummaryCard: View {
    let summary: String
    var onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            SymbolIcon(name: "checkmark", size: 10, weight: .heavy)
                .foregroundStyle(Theme.Colors.white)
                .frame(width: 24, height: 24)
                .background(Theme.Colors.green, in: Circle())
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 0) {
                Text("Your answers")
                    .textStyle(.footnoteEmphasis, color: Theme.Colors.muted)
                Text(summary)
                    .textStyle(.subhead)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button("Edit", action: onEdit)
                .buttonStyle(.plain)
                .textStyle(.footnoteEmphasis, color: Theme.Colors.purple)
                .frame(minWidth: 36, minHeight: Theme.Size.touch)
                .contentShape(Rectangle())
                .accessibilityLabel("Edit your answers")
        }
        .padding(.vertical, 10)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .cardSurface(radius: Theme.Radius.note)
    }
}

// MARK: - Picks

/// One-sentence reason for a pick.
struct ReasonRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Glyph.sparkle(16)
                .foregroundStyle(Theme.Colors.purple)
            Text(text)
                .textStyle(.footnote, color: Theme.Colors.ink2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Theme.Colors.reasonFill, in: RoundedRectangle(cornerRadius: Theme.Radius.statusTile, style: .continuous))
    }
}

/// Compact pick: the whole card is tappable.
struct PickCardCompact: View {
    let pick: ConciergePick
    /// Why it was picked, when it differs from the script's line.
    var reason: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(pick.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Theme.Size.pickThumbnail, height: Theme.Size.pickThumbnail)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.thumbnailLarge, style: .continuous))

                    VStack(alignment: .leading, spacing: 0) {
                        Text(pick.kind.uppercased())
                            .textStyle(.capsTight, color: Theme.Colors.purple)
                        Text(pick.title)
                            .textStyle(.headline)
                        Text(pick.meta)
                            .textStyle(.footnote, color: Theme.Colors.muted)
                        LinkLabel(title: pick.cta, chevronSize: 10)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                ReasonRow(text: reason ?? pick.why)
            }
            .padding(12)
            .cardSurface()
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(pick.kind): \(pick.title). \(pick.meta). \(reason ?? pick.why)")
        .accessibilityHint(pick.cta)
    }
}

/// Open-display pick: large image and a red button.
struct PickCardLarge: View {
    let pick: ConciergePick
    var reason: String?
    var imageHeight: CGFloat = 110
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardImage(name: pick.imageName, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.thumbnailLarge, style: .continuous))

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(pick.kind.uppercased())
                        .textStyle(.capsTight, color: Theme.Colors.purple)
                    Text(pick.title)
                        .textStyle(.headline)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                Button(pick.cta, action: action)
                    .buttonStyle(FilledButtonStyle(kind: .red, compact: true, fullWidth: false))
            }

            Text(pick.meta)
                .textStyle(.footnote, color: Theme.Colors.muted)
                .lineLimit(1)

            ReasonRow(text: reason ?? pick.why)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(radius: Theme.Radius.groupCard)
    }
}

// MARK: - Trip brief (open display)

/// "Your trip so far": updates live as chips change.
struct TripBriefPanel: View {
    let model: ConciergeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your trip so far")
                    .textStyle(.section)
                    .accessibilityAddTraits(.isHeader)
                Text("Updates as you answer")
                    .textStyle(.footnote, color: Theme.Colors.muted)
            }
            .padding(.bottom, 8)

            row("Destination", model.destination) { Glyph(shape: PinShape(), size: 20, lineWidth: 1.9) }
            row("Dates", model.datesWithNightsText) { SymbolIcon(name: "calendar", size: 17) }
            row("Budget", model.budgetText) { SymbolIcon(name: "dollarsign", size: 17) }
            row("Vibe", model.vibeText) { Glyph.sparkle(20, lineWidth: 1.9) }
            row("Dining", model.diningText) { SymbolIcon(name: "fork.knife", size: 17) }

            if let followUps = model.followUps {
                Button(followUps.cta) { model.showPicks() }
                    .buttonStyle(FilledButtonStyle())
                    .padding(.top, 12)
            }
        }
        .padding(20)
        .panelSurface()
        .riseIn(order: 2)
    }

    private func row(_ label: String, _ value: String, @ViewBuilder icon: () -> some View) -> some View {
        HStack(spacing: 12) {
            icon()
                .foregroundStyle(Theme.Colors.purple)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.tintPurple, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .textStyle(.footnote, color: Theme.Colors.muted)
                Text(value)
                    .textStyle(.bodyEmphasis)
                    .lineLimit(1)
                    .contentTransition(.opacity)
                    .animation(Theme.Motion.select, value: value)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 62)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Colors.hairline)
                .frame(height: Theme.Size.border)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Concierge components") {
    let content = LifestyleContent.sample
    let model = LifestyleStore.preview().concierge
    return ScrollView {
        VStack(spacing: 8) {
            UserBubble(text: content.concierge.userRequest)
            ConciergeBubble(model.introLine)
            ConciergeBubble { TypingDots() }
            FollowUpCard(model: model)
            AnswersSummaryCard(summary: model.answersSummary) {}
            ForEach(content.concierge.picks) { pick in
                PickCardCompact(pick: pick) {}
            }
            ForEach(content.concierge.picks) { pick in
                PickCardLarge(pick: pick) {}
            }
            TripBriefPanel(model: model)
            DisclosureCard(text: content.concierge.disclosure)
            ComposerBar(text: .constant("")) {}
        }
        .padding(16)
    }
    .background(AmbientBackground())
}
