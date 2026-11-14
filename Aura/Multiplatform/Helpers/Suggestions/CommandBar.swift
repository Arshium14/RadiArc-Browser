//
//  CommandBar.swift
//  Aura
//
//  Created by Reyna Myers on 1/5/24.
//

import SwiftUI
import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

struct CommandBar: View {
    @EnvironmentObject var settings: SettingsVariables
    @EnvironmentObject var variables: ObservableVariables

    @Binding var commandBarText: String
    @Binding var searchSubmitted: Bool
    @Binding var collapseHeightAnimation: Bool
    @Binding var isBrowseForMe: Bool

    @State private var suggestions: [String] = []
    @State private var suggestionsForText: String?
    @State private var selectedSuggestion = -1
    @State private var hoveredSuggestion: Int?
    @State private var dismissed = false
    @FocusState private var isFocused: Bool

    init(commandBarText: Binding<String>, searchSubmitted: Binding<Bool>,
         collapseHeightAnimation: Binding<Bool>, isBrowseForMe: Binding<Bool>) {
        _commandBarText = commandBarText
        _searchSubmitted = searchSubmitted
        _collapseHeightAnimation = collapseHeightAnimation
        _isBrowseForMe = isBrowseForMe
    }

    private var query: String {
        commandBarText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var visibleSuggestions: [String] {
        guard suggestionsForText == commandBarText,
              !query.isEmpty || settings.historyEnabled else { return [] }
        return suggestions
    }

    private var selectedQuery: String {
        let candidates = visibleSuggestions
        return candidates.indices.contains(selectedSuggestion) ? candidates[selectedSuggestion] : query
    }
    
    var body: some View {
        if !searchSubmitted {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Search or enter URL", text: Binding(
                            get: { commandBarText },
                            set: { value in
                                selectedSuggestion = -1
                                commandBarText = value
                            }
                        ))
                        .font(.body)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.go)
                        #endif
                        .onSubmit { submit(selectedQuery, browseForMe: false) }
                        .onKeyPress(.downArrow) {
                            moveSelection(down: true)
                            proxy.scrollTo(selectedSuggestion, anchor: .center)
                            return .handled
                        }
                        .onKeyPress(.upArrow) {
                            moveSelection(down: false)
                            proxy.scrollTo(selectedSuggestion, anchor: .center)
                            return .handled
                        }
                        .onKeyPress(.escape) {
                            dismiss()
                            return .handled
                        }

                        Button(action: dismiss) {
                            Image(systemName: "xmark")
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Close command bar")
                        .keyboardShortcut(.escape, modifiers: [])
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 4)
                    .padding(.vertical, 4)

                    Divider()

                    ScrollView {
                        LazyVStack(spacing: 4) {
                            if !query.isEmpty {
                                suggestionRow(query, index: -1).id(-1)
                            }
                            ForEach(Array(visibleSuggestions.enumerated()), id: \.offset) { index, suggestion in
                                suggestionRow(suggestion, index: index).id(index)
                            }
                            if query.isEmpty && visibleSuggestions.isEmpty {
                                Text("Search the web or enter a website address.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                            }
                        }
                        .padding(8)
                    }
                    .scrollDismissesKeyboard(.never)
                }
                .frame(maxWidth: 560, maxHeight: 360)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear {
                dismissed = false
                collapseHeightAnimation = true
                isFocused = true
            }
            .onDisappear { dismissed = true }
            .onChange(of: commandBarText) {
                selectedSuggestion = -1
                hoveredSuggestion = nil
            }
            .onChange(of: settings.historyEnabled) {
                if query.isEmpty { loadHistory() }
            }
            .task(id: commandBarText) { [text = commandBarText] in
                await loadSuggestions(for: text)
            }
        }
    }

    private func suggestionRow(_ text: String, index: Int) -> some View {
        let selected = selectedSuggestion == index
        return HStack(spacing: 4) {
            Button {
                submit(text, browseForMe: false)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text(text)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.right")
                        .frame(width: 24, height: 24)
                        .opacity(selected ? 1 : 0.25)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search for \(text)")
            .accessibilityAddTraits(selected ? [.isSelected] : [])

            if !settings.hideBrowseForMe {
                // Sibling controls: an AI tap must never also trigger navigation.
                Button {
                    submit(text, browseForMe: true)
                } label: {
                    Label("Browse", systemImage: "sparkles")
                        .font(.callout)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Browse for Me: \(text)")
            }
        }
        .font(.body)
        .foregroundStyle(.primary)
        .background(Color.primary.opacity(selected ? 0.08 : (hoveredSuggestion == index ? 0.04 : 0)))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { hovering in hoveredSuggestion = hovering ? index : nil }
    }

    private func moveSelection(down: Bool) {
        let count = visibleSuggestions.count
        guard count > 0 else {
            selectedSuggestion = -1
            return
        }
        if down {
            selectedSuggestion = selectedSuggestion < count - 1 ? selectedSuggestion + 1 : -1
        } else {
            selectedSuggestion = selectedSuggestion >= 0 ? selectedSuggestion - 1 : count - 1
        }
    }

    private func submit(_ text: String, browseForMe: Bool) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !searchSubmitted, !dismissed else { return }
        commandBarText = text
        if settings.historyEnabled {
            var history = UserDefaults.standard.stringArray(forKey: "commandBarHistory") ?? []
            history.insert(text, at: 0)
            UserDefaults.standard.set(Self.uniqueQueries(history), forKey: "commandBarHistory")
        }
        isFocused = false
        // The root consumes this event before hiding the bar. Hiding it here
        // would unmount the root's submission observer too early.
        isBrowseForMe = browseForMe
        searchSubmitted = true
    }

    private func dismiss() {
        dismissed = true
        isFocused = false
        collapseHeightAnimation = false
        variables.tabBarShown = false
        variables.commandBarShown = false
    }

    private func loadHistory() {
        selectedSuggestion = -1
        suggestions = settings.historyEnabled
            ? Self.uniqueQueries(UserDefaults.standard.stringArray(forKey: "commandBarHistory") ?? [])
            : []
        suggestionsForText = commandBarText
    }

    @MainActor
    private func loadSuggestions(for text: String) async {
        guard !Task.isCancelled, !dismissed, !searchSubmitted,
              commandBarText == text else { return }
        selectedSuggestion = -1
        suggestions = []
        suggestionsForText = text
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            loadHistory()
            return
        }
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
            try Task.checkCancellation()
            guard !dismissed, !searchSubmitted, commandBarText == text else { return }
            let results = try await CommandBarSuggestions.fetch(query: query)
            guard !Task.isCancelled, !dismissed, !searchSubmitted,
                  commandBarText == text else { return }
            suggestions = results.filter { $0.caseInsensitiveCompare(query) != .orderedSame }
            suggestionsForText = text
        } catch {
            // Suggestions are optional; never publish an old request's results
            // or error over newer input. The typed query still works offline.
        }
    }

    private static func uniqueQueries(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return Array(values.compactMap { value in
            let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, seen.insert(value.lowercased()).inserted else { return nil }
            return value
        }.prefix(10))
    }
}

enum CommandBarSuggestions {
    static func request(for query: String) -> URLRequest? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "toolbarqueries.google.com"
        components.path = "/complete/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "output", value: "toolbar"),
            URLQueryItem(name: "hl", value: "en")
        ]
        // Some query decoders treat a literal '+' as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        guard let url = components.url else { return nil }
        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
    }

    static func fetch(query: String) async throws -> [String] {
        guard let request = request(for: query) else { return [] }
        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else { return [] }
        return parse(data)
    }

    static func parse(_ data: Data) -> [String] {
        let delegate = SuggestionXMLDelegate()
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse() else { return [] }
        return delegate.suggestions
    }
}

private final class SuggestionXMLDelegate: NSObject, XMLParserDelegate {
    var suggestions: [String] = []
    private var seen = Set<String>()

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        guard elementName == "suggestion", let rawValue = attributeDict["data"] else { return }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, suggestions.count < 10,
              seen.insert(value.lowercased()).inserted else { return }
        suggestions.append(value)
    }
}
