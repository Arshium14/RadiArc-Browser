//
//  MainMenu.swift
//  Styling
//
//  Created by Mark C. Maxwell on The New Lux
//  Copyright © 2020. All rights reserved.
//

import SwiftUI


public struct BrowserView: View {
    @ObservedObject var webViewStore: WebViewStore
    @EnvironmentObject private var settings: SettingsVariables
    @Environment(\.colorScheme) private var colorScheme

    public init(webViewStore: WebViewStore) {
        self.webViewStore = webViewStore
    }

    public var body: some View {
        WebView(webView: webViewStore.webView)
            .overlay(alignment: .top) {
                if webViewStore.webView.isLoading {
                    ProgressView(value: webViewStore.webView.estimatedProgress)
                        .progressViewStyle(.linear)
                        .tint(.secondary)
                        .accessibilityLabel("Loading page")
                        .allowsHitTesting(false)
                }
            }
            .task(id: appearanceTaskID) {
                let store = webViewStore
                guard !store.webView.isLoading, let url = store.webView.url else { return }
                let mode = websiteAppearanceMode
                if mode != "none" {
                    do {
                        try await Task.sleep(for: .seconds(max(0, settings.jsInjectionDelay)))
                    } catch { return }
                }
                guard !Task.isCancelled, store.webView.url == url, !store.webView.isLoading else { return }
                store.JSperformScript(script: websiteAppearanceScript(mode: mode, navigation: url.absoluteString))
            }
    }

    private var websiteAppearanceMode: String {
        let wantsDark = settings.forceDarkModeTime == "dark" || (settings.forceDarkModeTime == "system" && colorScheme == .dark)
        guard wantsDark, ["basic", "advanced"].contains(settings.forceDarkMode) else { return "none" }
        return settings.forceDarkMode
    }

    private var appearanceTaskID: String {
        "\(ObjectIdentifier(webViewStore))-\(webViewStore.webView.url?.absoluteString ?? "")-\(webViewStore.webView.isLoading)-\(websiteAppearanceMode)-\(settings.jsInjectionDelay)"
    }
}

private func jsQuoted(_ value: String) -> String {
    value.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "'", with: "\\'")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
}

func websiteAppearanceScript(mode: String, navigation: String) -> String {
    let mode = ["basic", "advanced"].contains(mode) ? mode : "none"
    let darkScript = mode == "basic" ? forceDarkModeBasic : forceDarkModeAdvanced + "\nwindow.toggleDarkMode(true);"
    return """
    (() => {
        const current = window.__solBrowserAppearance;
        if (current?.mode === '\(mode)' && current?.navigation === '\(jsQuoted(navigation))') return;
        current?.restore();
        if ('\(mode)' === 'none') return;
        const readStyle = node => Object.fromEntries(Array.from(node.style).map(name => [name, [node.style.getPropertyValue(name), node.style.getPropertyPriority(name)]]));
        const before = Array.from(document.querySelectorAll('*')).map(node => ({node, style: readStyle(node), processed: node.is_dnm_processed}));
        \(darkScript)
        const changes = before.map(({node, style, processed}) => {
            const after = readStyle(node);
            const names = new Set([...Object.keys(style), ...Object.keys(after)]);
            const properties = Array.from(names).filter(name => JSON.stringify(style[name]) !== JSON.stringify(after[name]));
            return {node, style, after, properties, processed};
        });
        window.__solBrowserAppearance = {
            mode: '\(mode)',
            navigation: '\(jsQuoted(navigation))',
            restore() {
                for (const {node, style, after, properties, processed} of changes) {
                    for (const name of properties) {
                        const applied = after[name] || ['', ''];
                        if (node.style.getPropertyValue(name) !== applied[0] || node.style.getPropertyPriority(name) !== applied[1]) continue;
                        if (style[name]) node.style.setProperty(name, ...style[name]);
                        else node.style.removeProperty(name);
                    }
                    node.is_dnm_processed = processed;
                }
                delete window.__solBrowserAppearance;
            }
        };
    })();
    """
}

public struct LoaderNavBar: View {
    @ObservedObject var webViewStore: WebViewStore
    
    public init(webViewStore: WebViewStore) {
    self.webViewStore = webViewStore
    }
    
    public var body: some View {
        HStack {
            Spacer()
        }
        .frame(height: 2)
        .background(
            Rectangle()
                .fill(Color.white)
                .allowsHitTesting(false)
                .disabled(true)
        )
        .frame(height: 2)
        .clipped()
    }
}

public struct NavigatorNavBar: View {
    @ObservedObject var webViewStore: WebViewStore

    public init(webViewStore: WebViewStore) {
    self.webViewStore = webViewStore
    }
    
    var title: String {
        (webViewStore.webView.title ?? "Error")
    }

    public var body: some View {
        HStack {
            Button(action: { self.webViewStore.webView.goBack() }) {
                Image(systemName: "chevron.left")
            }

            Text(self.title)
                .bold()
                .lineLimit(1)
                .animation(.none)

            Button(action: { self.webViewStore.webView.goForward() }) {
                Image(systemName: "chevron.right")
            }
        }
    }
}
