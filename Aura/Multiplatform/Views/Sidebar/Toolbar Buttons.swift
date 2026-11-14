//
//  Toolbar Buttons.swift
//  iPad browser
//
//  Created by Reyna Myers on 19/4/24.
//

import SwiftUI
import WebKit
import SwiftData

struct ToolbarButtonsView: View {
    @EnvironmentObject var variables: ObservableVariables
    @EnvironmentObject var manager: WebsiteManager
    @EnvironmentObject var settings: SettingsVariables
    var geo: GeometryProxy

    var body: some View {
        HStack(spacing: 0) {
            Button {
                variables.hideSidebar.toggle()
            } label: {
                Image(systemName: settings.sidebarLeft ? "sidebar.left" : "sidebar.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Toggle Sidebar")

            Spacer(minLength: 0)

            Button {
                manager.selectedWebView?.webView.goBack()
            } label: {
                Image(systemName: "chevron.backward").frame(width: 44, height: 44)
            }
            .disabled(!(manager.selectedWebView?.webView.canGoBack ?? false))
            .accessibilityLabel("Back")

            Button {
                manager.selectedWebView?.webView.goForward()
            } label: {
                Image(systemName: "chevron.forward").frame(width: 44, height: 44)
            }
            .disabled(!(manager.selectedWebView?.webView.canGoForward ?? false))
            .accessibilityLabel("Forward")

            Button {
                variables.searchInSidebar = manager.selectedWebView?.webView.url?.absoluteString ?? variables.searchInSidebar
                manager.selectedWebView?.reload()
            } label: {
                Image(systemName: "arrow.clockwise").frame(width: 44, height: 44)
            }
            .disabled(manager.selectedWebView == nil)
            .accessibilityLabel("Reload")
        }
        .font(.body.weight(.medium))
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }
}


