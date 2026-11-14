//
// Aura
// BoostSettings.swift
//
// Created by Reyna Myers on 12/10/24
//
// Copyright ©2024 DoorHinge Apps.
//

import SwiftUI

struct BoostSettings: View {
    @ObservedObject var settings: SettingsVariables
    let startHex: String
    let endHex: String

    var body: some View {
        Form {
            Section {
                Stepper(value: $settings.jsInjectionDelayBoosts, in: 0...20, step: 0.25) {
                    LabeledContent("Boost Delay") {
                        Text("\(settings.jsInjectionDelayBoosts, specifier: "%.2f") seconds")
                    }
                }
                Stepper(value: $settings.jsInjectionDelay, in: 0...20, step: 0.25) {
                    LabeledContent("Website Dark Mode Delay") {
                        Text("\(settings.jsInjectionDelay, specifier: "%.2f") seconds")
                    }
                }
            } header: {
                Text("Script Timing")
            } footer: {
                Text("Wait before applying saved boosts or website dark mode. Longer delays can help on slow pages; shorter delays may run before a page is ready. These controls do not create or enable boosts.")
            }

            Section {
                TextField("User Agent", text: $settings.userAgent, axis: .vertical)
                    .autocorrectionDisabled()
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
            } header: {
                Text("Website Compatibility")
            } footer: {
                Text("The user agent identifies this browser to websites. Changing it can affect compatibility. Applies when creating a new web view; close and reopen existing tabs to use it.")
            }
        }
        .navigationTitle("Boosts & Advanced")
    }
}
