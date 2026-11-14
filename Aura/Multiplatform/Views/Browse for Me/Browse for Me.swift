//
//  ContentView.swift
//  Perplexity API
//
//  Created by Reyna Myers on 19/6/24.
//

import SwiftUI
import MarkdownUI


struct BrowseForMe: View {
    @EnvironmentObject var variables: ObservableVariables
    @AppStorage("apiKey") private var apiKey = ""

    @State private var searchText: String
    @State private var searchResponse: String
    @Binding var closeSheet: Bool

    @State private var searching = false
    @State private var failure: PerplexityError?
    @State private var request: SearchRequest?
    @FocusState private var queryFocused: Bool

    private struct SearchRequest: Hashable {
        let id = UUID()
        let prompt: String
    }

    init(searchText: String, searchResponse: String, closeSheet: Binding<Bool>) {
        _searchText = State(initialValue: searchText)
        _searchResponse = State(initialValue: searchResponse)
        _closeSheet = closeSheet
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        _request = State(initialValue: query.isEmpty || !searchResponse.isEmpty
                         ? nil : SearchRequest(prompt: query))
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var missingAPIKey: Bool {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Label("Browse for Me", systemImage: "sparkles")
                    .font(.headline)
                Spacer(minLength: 0)
                Button(action: close) {
                    Label("Close", systemImage: "xmark")
                        .font(.callout)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }

            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask a question", text: Binding(
                    get: { searchText },
                    set: { value in
                        // Invalidate before a pending response can publish, even
                        // if the edit leaves the trimmed query unchanged.
                        cancelSearch()
                        searchText = value
                        searchResponse = ""
                        failure = nil
                    }
                ), axis: .vertical)
                    .font(.body)
                    .lineLimit(1...3)
                    .textFieldStyle(.plain)
                    .focused($queryFocused)
                    .padding(12)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    #if !os(macOS)
                    .submitLabel(.search)
                    #endif
                    .onSubmit(startSearch)
                    .onKeyPress(.escape) {
                        close()
                        return .handled
                    }
                    .accessibilityLabel("Browse for Me question")
                Button("Search", action: startSearch)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(query.isEmpty || searching || missingAPIKey)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if missingAPIKey {
                        settingsNotice
                    } else if searching {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Searching the web…")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .accessibilityElement(children: .combine)
                    } else if let failure {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Search couldn't be completed", systemImage: "exclamationmark.circle")
                                .font(.headline)
                            Text(failure.localizedDescription)
                                .foregroundStyle(.secondary)
                            HStack {
                                Button("Try Again", action: startSearch)
                                    .buttonStyle(.bordered)
                                    .disabled(query.isEmpty)
                                if failure.needsSettings {
                                    Button("Open Settings") { variables.showSettings = true }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    } else if searchResponse.isEmpty {
                        Text("Ask a question to get an answer from the web. Searches are sent to Perplexity.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    if !searchResponse.isEmpty {
                        Markdown(searchResponse)
                            .markdownTheme(.basic)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: 720, maxHeight: 760, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .task(id: request) { [request] in
            await performSearch(request)
        }
        .onChange(of: apiKey) {
            cancelSearch()
            failure = nil
        }
        .onChange(of: closeSheet) {
            if !closeSheet { cancelSearch() }
        }
        .onDisappear { cancelSearch() }
    }

    private var settingsNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connect Perplexity", systemImage: "key")
                .font(.headline)
            Text("Add your Perplexity API key in Settings to use Browse for Me. No search is sent until a key is available.")
                .foregroundStyle(.secondary)
            Button("Open Settings") { variables.showSettings = true }
                .buttonStyle(.bordered)
            Link("Get a Perplexity API key", destination: URL(string: "https://www.perplexity.ai/settings/api")!)
                .font(.callout)
        }
    }

    private func startSearch() {
        guard !query.isEmpty, !searching, closeSheet else { return }
        guard !missingAPIKey else {
            cancelSearch()
            failure = .missingAPIKey
            return
        }
        queryFocused = false
        searchResponse = ""
        failure = nil
        searching = true
        // A new identity allows an explicit retry of the same query.
        request = SearchRequest(prompt: query)
    }

    private func cancelSearch() {
        request = nil
        searching = false
    }

    private func close() {
        cancelSearch()
        queryFocused = false
        closeSheet = false
    }

    @MainActor
    private func performSearch(_ snapshot: SearchRequest?) async {
        guard let snapshot, request == snapshot, closeSheet, !Task.isCancelled else { return }
        searching = true
        failure = nil
        defer {
            // An old task must not stop the progress indicator for its successor.
            if request == snapshot { searching = false }
        }
        guard !missingAPIKey else {
            failure = .missingAPIKey
            return
        }
        let key = apiKey
        do {
            let response = try await PerplexityClient(apiKey: key).completion(prompt: snapshot.prompt)
            guard !Task.isCancelled, request == snapshot, closeSheet,
                  query == snapshot.prompt, apiKey == key else { return }
            searchResponse = response
        } catch is CancellationError {
            // Dismissal and replacement are not user-visible failures.
        } catch {
            guard !Task.isCancelled, request == snapshot, closeSheet,
                  query == snapshot.prompt, apiKey == key else { return }
            failure = (error as? PerplexityError) ?? .network(.unknown)
        }
    }
}
