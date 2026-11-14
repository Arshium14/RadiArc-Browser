//
//  Favicons.swift
//  Aura
//
//  Created by Reyna Myers on 22/6/24.
//

import SwiftUI

struct Favicons: View {
    @ObservedObject var settings: SettingsVariables
    let startHex: String
    let endHex: String

    var body: some View {
        Form {
            Section("Website Icons") {
                Picker("Icon Shape", selection: $settings.faviconShape) {
                    Text("Circle").tag("circle")
                    Text("Rounded Square").tag("squircle")
                    Text("Square").tag("square")
                }
                Toggle("Cache Website Icons", isOn: $settings.faviconLoadingStyle)
            }

            Section("Favorites") {
                Toggle("Show Website Names", isOn: $settings.favoritesStyle)
                Stepper(value: $settings.favoriteTabCornerRadius, in: 0...50, step: 1) {
                    LabeledContent("Corner Radius", value: "\(Int(settings.favoriteTabCornerRadius)) pt")
                }
                Stepper(value: $settings.favoriteTabBorderWidth, in: 0...10, step: 1) {
                    LabeledContent("Border Width", value: "\(Int(settings.favoriteTabBorderWidth)) pt")
                }
            }

            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                Section("Tab Overview") {
                    Stepper(value: $settings.gridColumnCount, in: 1...5, step: 1) {
                        LabeledContent("Grid Columns", value: "\(Int(settings.gridColumnCount))")
                    }
                }
            }
            #endif
        }
        .navigationTitle("Icons & Favorites")
    }
}

#Preview {
    NavigationStack {
        Favicons(settings: SettingsVariables(), startHex: "8A3CEF", endHex: "84F5FE")
    }
}
