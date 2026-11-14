//
//  SearchEngine.swift
//  Aura
//
//  Created by Reyna Myers on 10/7/24.
//

import SwiftUI

struct SearchSettings: View {
    @ObservedObject var settings: SettingsVariables
    let startHex: String
    let endHex: String

    private let engines = [
        (name: "Google", endpoint: "https://www.google.com/search?q="),
        (name: "Bing", endpoint: "https://www.bing.com/search?q="),
        (name: "DuckDuckGo", endpoint: "https://duckduckgo.com/?q="),
        (name: "Yahoo!", endpoint: "https://search.yahoo.com/search?q="),
        (name: "Ecosia", endpoint: "https://www.ecosia.org/search?q=")
    ]

    var body: some View {
        Form {
            Section {
                Picker("Search Engine", selection: $settings.searchEngine) {
                    ForEach(engines, id: \.endpoint) { engine in
                        Text(engine.name).tag(engine.endpoint)
                    }
                    if !engines.contains(where: { $0.endpoint == settings.searchEngine }) {
                        Text("Custom").tag(settings.searchEngine)
                    }
                }
                NavigationLink("Custom Search Engine…") {
                    CustomSearchEngineSettings(settings: settings)
                }
            } footer: {
                Text("Used when you enter a search instead of a website address.")
            }

            Section {
                Toggle("Hide Search Symbol in Tab Titles", isOn: $settings.hideMagnifyingGlassSearch)
            } header: {
                Text("Tab Titles")
            } footer: {
                Text("Remove the magnifying glass from search tab titles. Applies to new titles; existing titles may need the browser to reopen.")
            }
        }
        .navigationTitle("Search")
    }
}

private struct CustomSearchEngineSettings: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: SettingsVariables
    @State private var endpoint = ""

    private var trimmedEndpoint: String {
        endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        guard let url = URLComponents(string: trimmedEndpoint),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil,
              url.fragment == nil else { return false }
        return trimmedEndpoint.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }

    var body: some View {
        Form {
            Section {
                TextField("Search URL", text: $endpoint, axis: .vertical)
                    .autocorrectionDisabled()
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
                    .textContentType(.URL)
            } header: {
                Text("Custom Search Engine")
            } footer: {
                Text("Enter a complete HTTP or HTTPS search endpoint, such as https://www.google.com/search?q=. Search words are appended to this URL, separated by + signs. Your current engine is kept until you save.")
            }

            if !endpoint.isEmpty && !isValid {
                Text("Enter a valid HTTP or HTTPS URL without spaces, credentials, or a fragment.")
                    .foregroundStyle(.secondary)
            }

            Button("Use This Search Engine") {
                guard isValid else { return }
                settings.searchEngine = trimmedEndpoint
                dismiss()
            }
            .disabled(!isValid)
        }
        .navigationTitle("Custom Search")
        .onAppear { endpoint = settings.searchEngine }
    }
}
