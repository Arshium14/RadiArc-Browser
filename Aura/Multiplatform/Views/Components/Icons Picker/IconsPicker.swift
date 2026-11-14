//
//  IconsPicker.swift
//  iPad browser
//
//  Created by Reyna Myers on 17/4/24.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// SpaceStorage.spaceIcon remains either an SF Symbol name or one emoji grapheme.
struct SpaceIcon: View {
    let icon: String
    var size: CGFloat = 20
    static let fallback = "square.grid.2x2"

    static func emoji(in value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count == 1 else { return nil }
        let scalars = value.unicodeScalars
        let isEmoji = scalars.contains { $0.properties.isEmojiPresentation }
            || scalars.contains { $0.properties.isEmoji && $0.value > 0x7F }
            || (scalars.contains { $0.properties.isEmoji }
                && scalars.contains { $0.value == 0xFE0F || $0.value == 0x20E3 })
        return isEmoji ? value : nil
    }

    static func isSymbol(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
#if os(macOS)
        return NSImage(systemSymbolName: value, accessibilityDescription: nil) != nil
#else
        return UIImage(systemName: value) != nil
#endif
    }

    static func normalized(_ value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return emoji(in: value) ?? (isSymbol(value) ? value : nil)
    }

    var body: some View {
        Group {
            if let emoji = Self.emoji(in: icon) {
                Text(emoji)
            } else {
                Image(systemName: Self.isSymbol(icon) ? icon : Self.fallback)
            }
        }
        .font(.system(size: size, weight: .medium))
        .foregroundStyle(.primary)
        .frame(width: size + 4, height: size + 4)
        .accessibilityHidden(true)
    }
}

/// Both layouts capture a model when presenting, never a moving selection index.
struct SpaceCustomizationButton: View {
    let space: SpaceStorage
    @State private var editingSpace: SpaceStorage?

    var body: some View {
        Button {
            editingSpace = space
        } label: {
            HStack(spacing: 10) {
                SpaceIcon(icon: space.spaceIcon)
                Text(space.spaceName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "ellipsis").font(.body)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Customize \(space.spaceName)")
        .sheet(item: $editingSpace) { editedSpace in
            SpaceAppearanceEditor(space: editedSpace).id(editedSpace.persistentModelID)
        }
    }
}

/// Cancel (including swipe dismissal) discards drafts. Done saves this space.
struct SpaceAppearanceEditor: View {
    let space: SpaceStorage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var icon: String
    @State private var startColor: Color
    @State private var endColor: Color
    @State private var showCustomColors = false
    @State private var saveError: String?

    private struct Palette: Identifiable {
        let name: String
        let start: String
        let end: String
        var id: String { name }
    }
    private static let palettes = [
        Palette(name: "Mist", start: "DCE5EA", end: "F0EDE8"),
        Palette(name: "Sage", start: "B9CEC1", end: "E5E8CD"),
        Palette(name: "Dusk", start: "C1BBD8", end: "E5CED4"),
        Palette(name: "Ocean", start: "ADC8DE", end: "CEE6E3"),
        Palette(name: "Sand", start: "DBC8AB", end: "EDDFCC"),
        Palette(name: "Rose", start: "DDBDBD", end: "F0DCCB")
    ]

    init(space: SpaceStorage) {
        self.space = space
        _name = State(initialValue: space.spaceName)
        _icon = State(initialValue: SpaceIcon.normalized(space.spaceIcon) ?? SpaceIcon.fallback)
        _startColor = State(initialValue: Color(hex: space.startHex.isEmpty ? "DCE5EA" : space.startHex))
        _endColor = State(initialValue: Color(hex: space.endHex.isEmpty ? "F0EDE8" : space.endHex))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Space") {
                    TextField("Name", text: $name)
                    NavigationLink {
                        IconsPicker(currentIcon: $icon)
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            SpaceIcon(icon: icon)
                        }.frame(minHeight: 44)
                    }
                }
                Section("Appearance") {
                    LinearGradient(colors: [startColor, endColor], startPoint: .bottomLeading, endPoint: .topTrailing)
                        .frame(height: 140)
                        .overlay {
                            HStack(spacing: 10) {
                                SpaceIcon(icon: icon)
                                Text(name.isEmpty ? "Space" : name)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .padding(16)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Space appearance preview")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 12)], spacing: 12) {
                        ForEach(Self.palettes) { palette in
                            Button {
                                startColor = Color(hex: palette.start)
                                endColor = Color(hex: palette.end)
                            } label: {
                                VStack(spacing: 4) {
                                    LinearGradient(colors: [Color(hex: palette.start), Color(hex: palette.end)], startPoint: .bottomLeading, endPoint: .topTrailing)
                                        .frame(height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay {
                                            if isSelected(palette) {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.semibold))
                                                    .padding(5)
                                                    .background(.regularMaterial, in: Circle())
                                            }
                                        }
                                    Text(palette.name).font(.caption).lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(palette.name)
                            .accessibilityAddTraits(isSelected(palette) ? .isSelected : [])
                        }
                    }.padding(.vertical, 4)
                    DisclosureGroup("Custom Colors", isExpanded: $showCustomColors) {
                        ColorPicker("First Color", selection: $startColor, supportsOpacity: false)
                        ColorPicker("Second Color", selection: $endColor, supportsOpacity: false)
                    }
                }
            }
            .foregroundStyle(.primary)
            .navigationTitle("Customize Space")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || SpaceIcon.normalized(icon) == nil)
                }
            }
            .alert("Couldn’t Save Space", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
        .frame(idealWidth: 440, idealHeight: 640)
    }

    private func isSelected(_ palette: Palette) -> Bool {
        Self.hex(startColor) == palette.start && Self.hex(endColor) == palette.end
    }

    // Unlike raw CGColor components, these conversions also handle grayscale.
    private static func hex(_ color: Color) -> String? {
#if os(macOS)
        guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        let red = rgb.redComponent, green = rgb.greenComponent, blue = rgb.blueComponent
#else
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
#endif
        return String(format: "%02X%02X%02X", Int((min(max(red, 0), 1) * 255).rounded()), Int((min(max(green, 0), 1) * 255).rounded()), Int((min(max(blue, 0), 1) * 255).rounded()))
    }

    private func save() {
        guard space.modelContext === modelContext, !space.isDeleted else {
            saveError = "This space is no longer available. Cancel to close the editor."
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let savedIcon = SpaceIcon.normalized(icon),
              let start = Self.hex(startColor), let end = Self.hex(endColor) else {
            saveError = "Choose a name, a valid icon, and two colors."
            return
        }
        let previous = (space.spaceName, space.spaceIcon, space.startHex, space.endHex)
        space.spaceName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        space.spaceIcon = savedIcon
        space.startHex = start
        space.endHex = end
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Restore only these fields, not unrelated pending tabs or spaces.
            (space.spaceName, space.spaceIcon, space.startHex, space.endHex) = previous
            saveError = error.localizedDescription
        }
    }
}


/// Only edits a draft binding; persistence belongs to the presenting editor.
struct IconsPicker: View {
    @Binding var currentIcon: String
    @State private var iconSearch = ""
    @State private var emojiInput = ""
    @State private var filter: IconFilter = .all

    enum IconFilter: String, CaseIterable {
        case all = "All", outline = "Outline", fill = "Filled", circle = "Circle"
    }

    // Legacy call sites remain source-compatible; the index is never used to save.
    init(currentIcon: Binding<String>, selectedSpaceIndex: Binding<Int> = .constant(0)) {
        _currentIcon = currentIcon
    }

    private static let symbols = Array(Set(sfNewIconOptions)).sorted().filter { SpaceIcon.isSymbol($0) }

    private var filteredSymbols: [String] {
        let search = iconSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return Self.symbols.filter { symbol in
            let matches = search.isEmpty || symbol.contains(search)
                || symbol.replacingOccurrences(of: ".", with: " ").contains(search)
            switch filter {
            case .all: return matches
            case .outline: return matches && !symbol.contains("fill")
            case .fill: return matches && symbol.contains("fill")
            case .circle: return matches && symbol.contains("circle")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SpaceIcon(icon: currentIcon, size: 28)
                    Text("Space Icon").font(.headline)
                    Spacer(minLength: 0)
                }
                Text("Use one emoji, including a flag or a joined emoji.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Emoji", text: $emojiInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                Button("Use Emoji") {
                    if let emoji = SpaceIcon.emoji(in: emojiInput) { currentIcon = emoji }
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
                .disabled(SpaceIcon.emoji(in: emojiInput) == nil)

                Divider()
                TextField("Search SF Symbols", text: $iconSearch)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
#if !os(macOS)
                    .textInputAutocapitalization(.never)
#endif
                Picker("Symbol style", selection: $filter) {
                    ForEach(IconFilter.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .frame(minHeight: 44)

                if filteredSymbols.isEmpty {
                    Text("No symbols found. Try a different search.").foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            currentIcon = symbol
                        } label: {
                            SpaceIcon(icon: symbol)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.primary.opacity(currentIcon == symbol ? 0.12 : 0.04))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.primary.opacity(currentIcon == symbol ? 0.4 : 0), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                        .accessibilityAddTraits(currentIcon == symbol ? .isSelected : [])
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Choose Icon")
        .onAppear { emojiInput = SpaceIcon.emoji(in: currentIcon) ?? "" }
    }
}

