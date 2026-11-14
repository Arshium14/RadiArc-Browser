//
//  General.swift
//  Aura
//
//  Created by Reyna Myers on 23/6/24.
//

import SwiftUI

struct General: View {
    @ObservedObject var settings: SettingsVariables
    let startHex: String
    let endHex: String

    var body: some View {
        Form {
            Section {
                NavigationLink("Search Engine & Search") {
                    SearchSettings(settings: settings, startHex: startHex, endHex: endHex)
                }
            }

            Section {
                Toggle("Command Bar on Launch", isOn: $settings.commandBarOnLaunch)
            } header: {
                Text("Startup")
            } footer: {
                Text("Open the command bar when the browser launches.")
            }

            Section {
                Toggle("Swipe Between Spaces", isOn: $settings.swipingSpaces)
                Toggle("Swipe to Go Back or Forward", isOn: Binding(
                    get: { !settings.swipeNavigationDisabled },
                    set: { settings.swipeNavigationDisabled = !$0 }
                ))
            } header: {
                Text("Navigation")
            } footer: {
                Text("Swipe between spaces in the expanded sidebar. Page navigation controls touchscreen swipes; trackpad navigation is unaffected.")
            }

            Section {
                Stepper(value: $settings.preloadingWebsites, in: 1...30, step: 1) {
                    LabeledContent("Background Tabs", value: "\(Int(settings.preloadingWebsites))")
                }
            } header: {
                Text("Performance")
            } footer: {
                Text("Limit how many websites stay loaded in the background. Lower values use less memory; higher values can make switching tabs faster. The limit is used when loading tabs.")
            }
        }
        .navigationTitle("General")
    }
}

#Preview {
    NavigationStack {
        General(settings: SettingsVariables(), startHex: "8A3CEF", endHex: "84F5FE")
    }
}
