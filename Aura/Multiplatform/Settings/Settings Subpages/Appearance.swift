//
//  UISettings.swift
//  Aura
//
//  Created by Reyna Myers on 23/6/24.
//

import SwiftUI

struct UISettings: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @ObservedObject var settings: SettingsVariables

    let startHex: String
    let endHex: String

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $settings.prefferedColorScheme) {
                    Text("System").tag("automatic")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            } footer: {
                Text("System follows your device appearance. Website colors are controlled separately below.")
            }

            Section {
                Picker("Tab Layout", selection: $settings.horizontalTabBar) {
                    Text("Vertical").tag(false)
                    Text("Horizontal").tag(true)
                }
                Picker("Sidebar Side", selection: $settings.sidebarLeft) {
                    Text("Left").tag(true)
                    Text("Right").tag(false)
                }
                .disabled(settings.horizontalTabBar)
                Toggle("Compact Mode", isOn: $settings.hideSidebar)
                    .disabled(settings.horizontalTabBar)
                Toggle("Reveal Sidebar on Hover", isOn: Binding(
                    get: { !settings.disableSidebarHover },
                    set: { settings.disableSidebarHover = !$0 }
                ))
                .disabled(settings.horizontalTabBar)
                Toggle("Show Browser Border", isOn: $settings.showBorder)
                Toggle("Show Share Button", isOn: $settings.shareButtonInTabBar)
            } header: {
                Text("Tabs & Sidebar")
            } footer: {
                Text("Compact mode keeps the vertical sidebar hidden; it is not a separate tab layout. Use the sidebar button or keyboard shortcut to reveal it. Hover reveal requires a mouse or trackpad.")
            }

            Section {
                Toggle("Reduce Motion", isOn: $settings.reduceMotion)
                Toggle("Launch Animation", isOn: $settings.launchAnimation)
                    .disabled(settings.reduceMotion || systemReduceMotion)
            } header: {
                Text("Motion")
            } footer: {
                Text("Reduce optional browser animations. Your device's Reduce Motion setting is also respected.")
            }

            Section {
                Picker("Website Dark Mode", selection: $settings.forceDarkMode) {
                    Text("Off").tag("none")
                    Text("Basic").tag("basic")
                    Text("Advanced").tag("advanced")
                }
                if settings.forceDarkMode != "none" {
                    Picker("Apply Dark Mode", selection: $settings.forceDarkModeTime) {
                        Text("With Browser Appearance").tag("system")
                        Text("Never").tag("light")
                        Text("Always").tag("dark")
                    }
                }
            } header: {
                Text("Websites")
            } footer: {
                Text("Experimental color adjustments for websites without dark mode. Basic inverts near-black and near-white colors; Advanced may affect readability. Changes apply to the current page and to pages you open next.")
            }

            Section {
                NavigationLink("Website Icons & Favorites") {
                    Favicons(settings: settings, startHex: startHex, endHex: endHex)
                }
            }
        }
        .navigationTitle("Appearance")
    }
}

// Still used by HistoryView and the legacy General view outside this directory.
func randomString(length: Int) -> String {
    let letters = "abcd efghijkl mnopqrstuvwxyz ABCDEFGHIJK LMNOPQRSTUVWXYZ "
    return String((0..<length).map { _ in letters.randomElement()! })
}

#Preview {
    NavigationStack {
        UISettings(settings: SettingsVariables(), startHex: "8A3CEF", endHex: "84F5FE")
    }
}
