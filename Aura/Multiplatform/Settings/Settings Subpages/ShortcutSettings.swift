//
//  ShortcutSettings.swift
//  Aura
//
//  Created by Reyna Myers on 10/7/24.
//

import SwiftUI

struct ShortcutSettings: View {
    @ObservedObject var settings: SettingsVariables
    let startHex: String
    let endHex: String

    // Observe the same persisted bindings that the browser's shortcut parser uses.
    @AppStorage("toggleSidebar - Shortcut") private var toggleSidebar = "⌘, s"
    @AppStorage("newTab - Shortcut") private var newTab = "⌘, t"
    @AppStorage("commandBar - Shortcut") private var commandBar = "⌘, l"
    @AppStorage("goBack - Shortcut") private var goBack = "⌘, ["
    @AppStorage("goForward - Shortcut") private var goForward = "⌘, ]"
    @AppStorage("reload - Shortcut") private var reload = "⌘, r"
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section {
                shortcutRow("New Tab", shortcut: newTab)
                shortcutRow("Command Bar", shortcut: commandBar)
                shortcutRow("Toggle Sidebar", shortcut: toggleSidebar)
                shortcutRow("Go Back", shortcut: goBack)
                shortcutRow("Go Forward", shortcut: goForward)
                shortcutRow("Reload", shortcut: reload)
                shortcutRow("Close Tab", shortcut: "⌘, w")
                shortcutRow("Settings", shortcut: "⌘, ,")
            } header: {
                Text("Browser Shortcuts")
            } footer: {
                Text("Connect a hardware keyboard to use these shortcuts. Hold Command to see available actions. The values above reflect your saved bindings.")
            }

            Section {
                Button("Reset Keyboard Shortcuts…", role: .destructive) {
                    confirmReset = true
                }
            } footer: {
                Text("Restore the browser's default key bindings. Other preferences are not changed.")
            }
        }
        .navigationTitle("Keyboard Shortcuts")
        .confirmationDialog("Reset keyboard shortcuts?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Shortcuts", role: .destructive) {
                settings.objectWillChange.send()
                settings.shortcuts.resetShortcuts()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func shortcutRow(_ title: String, shortcut: String) -> some View {
        let keys = shortcut.components(separatedBy: ", ")
        let spokenKeys = keys.map { key in
            switch key {
            case "⌘": return "Command"
            case "⌥": return "Option"
            case "⌃": return "Control"
            case "⇧": return "Shift"
            case "[": return "Left Bracket"
            case "]": return "Right Bracket"
            case ",": return "Comma"
            default: return key.uppercased()
            }
        }.joined(separator: " + ")

        return LabeledContent(title, value: keys.joined().uppercased())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(spokenKeys)
    }
}

#Preview {
    NavigationStack {
        ShortcutSettings(settings: SettingsVariables(), startHex: "8A3CEF", endHex: "84F5FE")
    }
}
