//
//  New Settings.swift
//  Aura
//
//  Created by Reyna Myers on 22/6/24.
//

import SwiftUI

struct NewSettings: View {
    @EnvironmentObject var settings: SettingsVariables
    @EnvironmentObject private var variables: ObservableVariables
    @Binding var presentSheet: Bool

    let startHex: String
    let endHex: String

    var body: some View {
        NavigationStack {
            List {
                Section("Settings") {
                    NavigationLink {
                        General(settings: settings, startHex: startHex, endHex: endHex)
                    } label: {
                        Label("General", systemImage: "gearshape")
                    }
                    NavigationLink {
                        UISettings(settings: settings, startHex: startHex, endHex: endHex)
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    NavigationLink {
                        PrivacySettings(settings: settings, history: variables.history)
                    } label: {
                        Label("Privacy & History", systemImage: "hand.raised")
                    }
                    NavigationLink {
                        ShortcutSettings(settings: settings, startHex: startHex, endHex: endHex)
                    } label: {
                        Label("Keyboard Shortcuts", systemImage: "keyboard")
                    }
                }

                Section {
                    NavigationLink {
                        AISettings(settings: settings, startHex: startHex, endHex: endHex)
                    } label: {
                        Label("AI Features", systemImage: "sparkles")
                    }
                    NavigationLink {
                        BoostSettings(settings: settings, startHex: startHex, endHex: endHex)
                    } label: {
                        Label("Boosts & Advanced", systemImage: "slider.horizontal.3")
                    }
                }

                Section {
                    NavigationLink {
                        SettingsAboutView(settings: settings, presentSheet: $presentSheet)
                    } label: {
                        Label("About Sol Browser", systemImage: "info.circle")
                    }
                } footer: {
                    Text("Sol Browser · Built on Aura Browser")
                }
            }
            .navigationTitle("Sol Browser")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentSheet = false
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
    }
}

private struct PrivacySettings: View {
    @ObservedObject var settings: SettingsVariables
    @ObservedObject var history: HistoryObservable
    @StateObject private var snapshotRefresher = SnapshotRefresher()
    @State private var confirmClearHistory = false
    @State private var confirmDeleteSnapshots = false
    @State private var savedSearchCount = 0

    var body: some View {
        Form {
            Section {
                Toggle("Save Browsing History", isOn: $settings.historyEnabled)
                NavigationLink("Browsing History") {
                    SettingsHistoryView(history: history)
                }
                Button("Clear Browsing History…", role: .destructive) {
                    confirmClearHistory = true
                }
                .disabled(history.items.isEmpty && savedSearchCount == 0)
            } header: {
                Text("History")
            } footer: {
                Text("Turning off history stops saving new visits. Existing history stays until you delete it. Clearing history also removes saved command bar searches, including Browse for Me prompts. It does not remove cookies, website data, or open tabs.")
            }

            Section {
                Toggle("Block Ads", isOn: $settings.adBlockEnabled)
            } header: {
                Text("Content Blocking")
            } footer: {
                Text("Use the built-in experimental ad blocker. Changes apply to newly loaded tabs; existing tabs may need to be closed and reopened.")
            }

            Section {
                Button("Delete Website Snapshots…", role: .destructive) {
                    confirmDeleteSnapshots = true
                }
            } header: {
                Text("Local Storage")
            } footer: {
                Text("Remove saved page previews. This does not clear cookies or browsing history. Snapshots can be recreated as you browse.")
            }
        }
        .navigationTitle("Privacy & History")
        .onAppear {
            savedSearchCount = UserDefaults.standard.stringArray(forKey: "commandBarHistory")?.count ?? 0
        }
        .confirmationDialog("Clear all browsing history?", isPresented: $confirmClearHistory, titleVisibility: .visible) {
            Button("Clear History", role: .destructive) {
                history.items.removeAll()
                UserDefaults.standard.removeObject(forKey: "commandBarHistory")
                savedSearchCount = 0
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This also clears saved command bar searches and cannot be undone. Open tabs and website data will be kept.")
        }
        .confirmationDialog("Delete all website snapshots?", isPresented: $confirmDeleteSnapshots, titleVisibility: .visible) {
            Button("Delete Snapshots", role: .destructive) {
                snapshotRefresher.deleteAllSnapshots()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

private struct SettingsHistoryView: View {
    @ObservedObject var history: HistoryObservable

    var body: some View {
        List {
            ForEach(history.items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title.flatMap { $0.isEmpty ? nil : $0 } ?? item.websiteURL)
                        .font(.headline)
                    Text(item.websiteURL)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Text(item.date, format: .dateTime.year().month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .onDelete(perform: history.removeItem)
        }
        .overlay {
            if history.items.isEmpty {
                ContentUnavailableView("No Browsing History", systemImage: "clock", description: Text("Saved visits will appear here."))
            }
        }
        .navigationTitle("Browsing History")
        #if os(iOS)
        .toolbar {
            EditButton()
                .disabled(history.items.isEmpty)
        }
        #endif
    }
}

private struct SettingsAboutView: View {
    @ObservedObject var settings: SettingsVariables
    @Binding var presentSheet: Bool
    @State private var confirmResetOnboarding = false

    var body: some View {
        Form {
            Section("Sol Browser") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")
                LabeledContent("Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown")
                Text("An independent browser built on Aura Browser. Not affiliated with Arc, The Browser Company, or Zen Browser.")
                    .foregroundStyle(.secondary)
            }

            Section("Attribution & License") {
                Text("Aura Browser by DoorHinge Apps, Reyna Myers, and contributors.")
                Link("Aura Browser Source", destination: URL(string: "https://github.com/doorhinge-apps/Aura-Browser")!)
                Link("Mozilla Public License 2.0", destination: URL(string: "https://www.mozilla.org/MPL/2.0/")!)
                Text("Sol Browser and its Aura-derived source are distributed under MPL-2.0. Original copyright notices are retained in the source.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Reset Onboarding…", role: .destructive) {
                    confirmResetOnboarding = true
                }
            } footer: {
                Text("Show setup again and clear the onboarding email. Your tabs and browser preferences are kept.")
            }
        }
        .navigationTitle("About")
        .confirmationDialog("Reset onboarding?", isPresented: $confirmResetOnboarding, titleVisibility: .visible) {
            Button("Reset Onboarding", role: .destructive) {
                settings.email = ""
                settings.onboardingDone = false
                presentSheet = false
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

#Preview {
    NewSettings(presentSheet: .constant(true), startHex: "8A3CEF", endHex: "84F5FE")
        .environmentObject(SettingsVariables())
        .environmentObject(ObservableVariables())
}
