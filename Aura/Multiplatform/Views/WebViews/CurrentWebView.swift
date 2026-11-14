//
//  CurrentWebView.swift
//  Aura
//
//  Created by Reyna Myers on 27/6/24.
//

import SwiftUI

struct CurrentWebView: View {
    @EnvironmentObject var variables: ObservableVariables
    
    @EnvironmentObject var manager: WebsiteManager
    
    var webGeo: GeometryProxy
    
    @State var readerView = false
    
    var body: some View {
        if let store = manager.selectedWebView {
            BrowserView(webViewStore: store)
                .frame(width: webGeo.size.width, height: webGeo.size.height)
        } else if variables.auraTab.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "sun.max")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.secondary)
                Text("Sol Browser")
                    .font(.title2.weight(.semibold))
                Text("Your next tab starts here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Button {
                    variables.commandBarShown = false
                    variables.tabBarShown = true
                } label: {
                    Label("Search or enter a URL", systemImage: "magnifyingglass")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(width: webGeo.size.width, height: webGeo.size.height)
        }
    }
}


