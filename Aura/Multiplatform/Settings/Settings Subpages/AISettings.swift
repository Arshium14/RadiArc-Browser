//
//  AISettings.swift
//  Aura
//
//  Created by Reyna Myers on 10/7/24.
//

import SwiftUI

struct AISettings: View {
    @ObservedObject var settings: SettingsVariables
    let startHex: String
    let endHex: String

    var body: some View {
        Form {
            Section {
                Toggle("Hide Browse for Me", isOn: $settings.hideBrowseForMe)
            } footer: {
                Text("Hide Browse for Me in menus and the command bar. Regular browsing and search do not require an AI key.")
            }

            Section {
                SecureField("Perplexity API Key (Optional)", text: $settings.apiKey)
                    .autocorrectionDisabled()
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
            } header: {
                Text("Perplexity")
            } footer: {
                Text("Used by Browse for Me. Requests are sent to Perplexity and may incur provider charges.")
            }

            Section {
                SecureField("OpenAI API Key (Optional)", text: $settings.openAPIKey)
                    .autocorrectionDisabled()
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
            } header: {
                Text("OpenAI")
            } footer: {
                Text("Used by OpenAI-powered features. This is separate from your Perplexity key and may incur provider charges.")
            }

            Section {
                Text("Keys are optional. Clear a field to remove its saved key. Keys are stored in this app's local preferences, not the system Keychain.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI Features")
    }
}
