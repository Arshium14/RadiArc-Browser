//
//  Space Picker.swift
//  Aura
//
//  Created by Reyna Myers on 24/5/24.
//

import SwiftUI
import SwiftData

struct SpacePicker: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SpaceStorage.spaceIndex) private var spaces: [SpaceStorage]
    @Binding var currentSpace: String
    @Binding var selectedSpaceIndex: Int
    @State private var hoveredSpaceID: PersistentIdentifier?
    @State private var editingSpace: SpaceStorage?
    @State private var saveError: String?

    private var selectedID: PersistentIdentifier? {
        spaces.indices.contains(selectedSpaceIndex) ? spaces[selectedSpaceIndex].persistentModelID : nil
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(spaces, id: \.persistentModelID) { space in
                        Button {
                            select(space)
                        } label: {
                            SpaceIcon(icon: space.spaceIcon)
                                .frame(width: 44, height: 44)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.primary.opacity(selectedID == space.persistentModelID ? 0.12 : hoveredSpaceID == space.persistentModelID ? 0.06 : 0))
                                }
                                .overlay(alignment: .bottom) {
                                    if selectedID == space.persistentModelID {
                                        Capsule().fill(Color.primary.opacity(0.6))
                                            .frame(width: 12, height: 2)
                                            .padding(.bottom, 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .id(space.persistentModelID)
                        .help(space.spaceName)
                        .accessibilityLabel(space.spaceName)
                        .accessibilityAddTraits(selectedID == space.persistentModelID ? .isSelected : [])
                        .onHover { hoveredSpaceID = $0 ? space.persistentModelID : nil }
                        .contextMenu {
                            Button("Customize Space", systemImage: "paintpalette") { editingSpace = space }
                            Button("Delete Space", systemImage: "trash", role: .destructive) { delete(space) }
                                .disabled(spaces.count <= 1)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
            .onAppear { revealSelection(using: proxy) }
            .onChange(of: selectedID) { revealSelection(using: proxy) }
            .onChange(of: spaces.map(\.persistentModelID)) { revealSelection(using: proxy) }
        }
        .frame(height: 44)
        .sheet(item: $editingSpace) { space in
            SpaceAppearanceEditor(space: space).id(space.persistentModelID)
        }
        .alert("Couldn’t Delete Space", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private func select(_ space: SpaceStorage) {
        guard let index = spaces.firstIndex(where: { $0.persistentModelID == space.persistentModelID }) else { return }
        selectedSpaceIndex = index
        currentSpace = space.spaceName
    }

    private func revealSelection(using proxy: ScrollViewProxy) {
        if let selectedID { proxy.scrollTo(selectedID, anchor: .center) }
    }

    private func delete(_ space: SpaceStorage) {
        guard spaces.count > 1,
              let deletedIndex = spaces.firstIndex(where: { $0.persistentModelID == space.persistentModelID }) else { return }
        let previousSelection = selectedID
        let remaining = spaces.filter { $0.persistentModelID != space.persistentModelID }
        let nextIndex = remaining.firstIndex(where: { $0.persistentModelID == previousSelection })
            ?? min(deletedIndex, remaining.count - 1)

        // Flush existing work first so a failed deletion can be rolled back alone.
        do {
            try modelContext.save()
        } catch {
            saveError = error.localizedDescription
            return
        }
        modelContext.delete(space)
        do {
            try modelContext.save()
            selectedSpaceIndex = nextIndex
            currentSpace = remaining[nextIndex].spaceName
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}
