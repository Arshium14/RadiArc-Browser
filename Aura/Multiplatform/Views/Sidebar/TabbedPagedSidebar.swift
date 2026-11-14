//
// Aura
// TabbedPagedSidebar.swift
//
// Created by Reyna Myers on 12/10/24
//
// Copyright ©2024 DoorHinge Apps.
//


import SwiftUI
import SwiftData
import WebKit

struct TabbedPagedSidebar: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SpaceStorage.spaceIndex) private var spaces: [SpaceStorage]
    @EnvironmentObject var variables: ObservableVariables
    @EnvironmentObject var settings: SettingsVariables
    @AppStorage("currentSpace") private var currentSpace = "Untitled"
    @AppStorage("selectedSpaceIndex") private var selectedSpaceIndex = 0
    @State private var saveError: String?
    var isHovering: Bool

#if os(visionOS)
    @Environment(\.openWindow) private var openWindow
#endif

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 8) {
                ToolbarButtonsView(geo: geo)
                    .frame(height: 44)
                    // Swiping here never competes with vertical tab scrolling.
                    .contentShape(Rectangle())
                    .simultaneousGesture(spaceSwipe)
                    .accessibilityHint(settings.swipingSpaces ? "Swipe horizontally on the toolbar to switch spaces" : "")

                if spaces.indices.contains(selectedSpaceIndex) {
                    SidebarSpaceParameter(currentSelectedSpaceIndex: selectedSpaceIndex, geo: geo)
                        .id(spaces[selectedSpaceIndex].persistentModelID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transaction { $0.animation = nil }
                } else {
                    Spacer(minLength: 0)
                }

                HStack(spacing: 2) {
                    Button {
                        variables.showSettings = true
                    } label: {
                        Image(systemName: "gearshape").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")

                    SpacePicker(currentSpace: $currentSpace, selectedSpaceIndex: $selectedSpaceIndex)
                        .frame(minWidth: 0, maxWidth: .infinity)

                    Button(action: addSpace) {
                        Image(systemName: "plus").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Add Space")
                }
                .font(.body)
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        // Accept the parent's actual width, including its overlay padding.
        .frame(minWidth: 0, idealWidth: 300, maxWidth: 300)
        .onAppear(perform: normalizeSelection)
        .onChange(of: spaces.map(\.persistentModelID)) { normalizeSelection() }
        .alert("Couldn’t Add Space", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
#if os(visionOS)
        .onAppear {
            if variables.isFirstWindow {
                openWindow(id: "mainWindow")
                variables.isFirstWindow = false
            }
        }
#endif
    }

    private var spaceSwipe: some Gesture {
        DragGesture(minimumDistance: 48).onEnded { value in
            guard settings.swipingSpaces, abs(value.translation.width) > 80,
                  abs(value.translation.width) > abs(value.translation.height) * 2 else { return }
            let next = selectedSpaceIndex + (value.translation.width < 0 ? 1 : -1)
            guard spaces.indices.contains(next) else { return }
            selectedSpaceIndex = next
            currentSpace = spaces[next].spaceName
        }
    }

    private func normalizeSelection() {
        guard !spaces.isEmpty else { return }
        selectedSpaceIndex = min(max(selectedSpaceIndex, 0), spaces.count - 1)
    }

    private func addSpace() {
        let space = SpaceStorage(spaceIndex: (spaces.map(\.spaceIndex).max() ?? -1) + 1,
                                 spaceName: "Untitled \(spaces.count + 1)", spaceIcon: SpaceIcon.fallback,
                                 favoritesUrls: [], pinnedUrls: [], tabUrls: [])
        modelContext.insert(space)
        do {
            try modelContext.save()
        } catch {
            modelContext.delete(space)
            saveError = error.localizedDescription
        }
    }
}

