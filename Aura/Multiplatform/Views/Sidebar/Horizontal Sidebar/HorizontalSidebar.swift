//
// Aura
// HorizontalSidebar.swift
//
// Created by Reyna Myers on 17/7/24
//
// Copyright ©2024 DoorHinge Apps.
//

import Foundation
import SwiftUI
import SwiftData
import WebKit
import SDWebImageSwiftUI


struct HorizontalSidebar: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \SpaceStorage.spaceIndex) var spaces: [SpaceStorage]
    
    let currentSelectedSpaceIndex: Int
    
    @EnvironmentObject var variables: ObservableVariables
    @EnvironmentObject var manager: WebsiteManager
    @EnvironmentObject var settings: SettingsVariables
    
    var geo: GeometryProxy
    
    @AppStorage("currentSpace") var currentSpace = "Untitled"
    @State private var hoverSidebarSearchField = false
    @State private var hoverNewTabSection = false
    @AppStorage("favoritesStyle") var favoritesStyle = false
    @AppStorage("faviconLoadingStyle") var faviconLoadingStyle = false
    @AppStorage("faviconShape") var faviconShape = "circle"
    @AppStorage("selectedSpaceIndex") var selectedSpaceIndex = 0
    
    @State private var draggedItem: String?
    @State private var draggedItemIndex: Int?
    @State private var currentHoverIndex: Int?
    @State var reorderingTabs: [String] = []
    
    @State var pdfData: Data? = nil
    
    @State private var saveError: String?

    var body: some View {
        Group {
            if spaces.indices.contains(currentSelectedSpaceIndex) {
                sidebarContent
            }
        }
        .font(.body)
        .foregroundStyle(.primary)
        .alert("Couldn’t Save Tabs", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private var sidebarContent: some View {
        HStack(spacing: 4) {
            // Sidebar Searchbar
            Button {
                if manager.selectedWebView != nil {
                    variables.tabBarShown = false
                    variables.commandBarShown.toggle()
                }
                else {
                    variables.commandBarShown.toggle()
                    variables.tabBarShown = false
                }
            } label: {
                ZStack {
#if !os(visionOS)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.primary.opacity(hoverSidebarSearchField ? 0.10 : 0.06))
                        .stroke(Color.primary.opacity(hoverSidebarSearchField ? 0.18 : 0), lineWidth: 1)
                    #endif
                    
                    HStack(spacing: 0) {
                        if manager.selectedWebView != nil {
                            if manager.selectedWebView?.webView.hasOnlySecureContent ?? false {
                                Menu(content: {
                                    Label("Secure", systemImage: "lock.fill")
                                }, label: {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.primary)
                                        .font(.body.weight(.medium))
                                        .hoverEffect(.highlight)
                                        .padding(.horizontal, 5)
                                        .padding(.leading, 5)
                                })
                            }
                            else {
                                Menu(content: {
                                    Label("Not Secure", systemImage: "lock.open.fill")
                                }, label: {
                                    Image(systemName: "lock.open.fill")
                                        .foregroundStyle(Color.red)
                                        .font(.body.weight(.medium))
                                        .hoverEffect(.highlight)
                                        .padding(.horizontal, 5)
                                        .padding(.leading, 5)
                                })
                            }
                        }
                        
                        if unformatURL(url: variables.searchInSidebar).isEmpty {
                            Text("Search or Enter URL")
                                .padding(.leading, 5)
                                .foregroundStyle(.primary)
                                .opacity(0.8)
                                .lineLimit(1)
                        }
                        else {
                            Text(unformatURL(url: variables.searchInSidebar))
                                .padding(.leading, 5)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        
                        if manager.selectedWebView != nil {
#if !os(visionOS)
                            if settings.shareButtonInTabBar {
                                Button(action: {
                                    let activityController = UIActivityViewController(activityItems: [manager.selectedWebView?.webView.url?.absoluteURL ?? URL("")!, manager.selectedWebView?.webView ?? WKWebView()], applicationActivities: nil)
                                    
                                    if let popoverController = activityController.popoverPresentationController {
                                        popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                                        
                                        popoverController.permittedArrowDirections = [.up]
                                        popoverController.permittedArrowDirections = []
                                    }
                                    
                                    UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.primary)
                                        .font(.body.weight(.medium))
                                        .hoverEffect(.highlight)
                                        //.padding(.horizontal, 5)
                                        //.padding(.trailing, 5)
                                        .padding(10)
                                }
                            }
                            #endif
                            
                            
                            Menu(content: {
                                ControlGroup {
                                    Button(action: {
                                        UIPasteboard.general.string = manager.selectedWebView?.webView.url?.absoluteString ?? ""
                                    }, label: {
                                        Label("Copy Url", systemImage: "link")
                                    })
                                    
                                    #if !os(visionOS)
                                    Button(action: {
                                        let activityController = UIActivityViewController(activityItems: [manager.selectedWebView?.webView.url?.absoluteURL ?? URL("")!, manager.selectedWebView?.webView ?? WKWebView()], applicationActivities: nil)
                                        
                                        if let popoverController = activityController.popoverPresentationController {
                                            popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                                            
                                            popoverController.permittedArrowDirections = [.up]
                                            popoverController.permittedArrowDirections = []
                                        }
                                        
                                        UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
#endif
                                }
                                
                                #if !os(visionOS)
                                Button(action: {
                                    let activityController = UIActivityViewController(activityItems: [manager.selectedWebView?.webView.url?.absoluteURL ?? URL("")!, manager.selectedWebView?.webView ?? WKWebView()], applicationActivities: nil)
                                    
                                    if let popoverController = activityController.popoverPresentationController {
                                        popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                                        popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                                        
                                        popoverController.permittedArrowDirections = [.up]
                                        popoverController.permittedArrowDirections = []
                                    }
                                    
                                    UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
                                }) {
                                    Label("Add to Home Screen", systemImage: "plus.square")
                                }
#endif
                                
                                Button(action: {
                                    withAnimation {
                                        variables.boostEditor.toggle()
                                    }
                                }, label: {
                                    Label("Boost Editor", systemImage: "paintbrush")
                                })
                                
                                
                                Button(action: {
                                    if variables.boosts.disabledBoosts.contains(unformatPlainURL(url: manager.selectedWebView?.webView.url?.absoluteString ?? "")) {
                                        variables.boosts.enableBoost(unformatPlainURL(url: manager.selectedWebView?.webView.url?.absoluteString ?? ""))
                                    }
                                    else {
                                        variables.boosts.disableBoost(unformatPlainURL(url: manager.selectedWebView?.webView.url?.absoluteString ?? ""))
                                    }
                                }, label: {
                                    if variables.boosts.disabledBoosts.contains(unformatPlainURL(url: manager.selectedWebView?.webView.url?.absoluteString ?? "")) {
                                        Label("Enable Boost", systemImage: "paintbrush.pointed.fill")
                                    }
                                    else {
                                        Label("Disable Boost", systemImage: "paintbrush.pointed")
                                    }
                                })
                                
                                /*Button(action: {
                                    
                                }, label: {
                                    Label("Save as PDF", systemImage: "arrow.down.document")
                                })
                                
                                ShareLink(items: pdfData!, label: {
                                    Label("Save as PDF", systemImage: "arrow.down.document")
                                })
                                .onAppear() {
                                    let pdfConfiguration = WKPDFConfiguration()
                                    
                                            pdfConfiguration.rect = CGRect(x: 0, y: 0, width: manager.selectedWebView?.webView.scrollView.contentSize.width, height: manager.selectedWebView?.webView.scrollView.contentSize.height)

                                    manager.selectedWebView?.webView.createPDF(configuration: pdfConfiguration) { result in
                                                switch result {
                                                case .success(let data):
                                                    guard let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
                                                        return
                                                    }

                                                    pdfData = data
                                                    
                                                    do {
                                                        let savePath = downloadsDirectory.appendingPathComponent(manager.selectedWebView?.webView?.url?.absoluteString ?? "PDF").appendingPathExtension("pdf")
                                                        
                                                        try data.write(to: savePath)

                                                        print("Successfully created and saved PDF at \(savePath)")
                                                    } catch let error {
                                                        print("Could not save pdf due to \(error.localizedDescription)")
                                                    }

                                                case .failure(let failure):
                                                    print(failure.localizedDescription)
                                                }
                                            }
                                }*/
                                
                                
                            }, label: {
                                Image(systemName: "switch.2")
                                    .foregroundStyle(.primary)
                                    .font(.body.weight(.medium))
                                    .hoverEffect(.highlight)
                                    .padding(.horizontal, 5)
                                    .padding(.trailing, 5)
                            })
                        }
                    }
                }
                .frame(height: 50)
                .onHover(perform: { hovering in
                    if hovering {
                        hoverSidebarSearchField = true
                    }
                    else {
                        hoverSidebarSearchField = false
                    }
                })
                .frame(width: 250)
            }.buttonStyle(.plain)
                .padding(.top, 2)
            
            
            Button {
                variables.tabBarShown.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.15), lineWidth: settings.favoriteTabBorderWidth)
                        .fill(Color.primary.opacity(hoverNewTabSection ? 0.08 : 0))
                    
                    Image(systemName: "plus")
                        .foregroundStyle(Color.primary)
                        .font(.body.weight(.medium))
                        .padding(10)
                }
                .frame(width: 50, height: 50)
                .onHover(perform: { hovering in
                    if hovering {
                        hoverNewTabSection = true
                    }
                    else {
                        hoverNewTabSection = false
                    }
                })
            }.buttonStyle(.plain)
                .onChange(of: manager.selectedWebView?.webView.url?.absoluteString ?? "") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        let newUrl = manager.selectedWebView?.webView.url?.absoluteString ?? ""
                        variables.searchInSidebar = newUrl

                        if manager.selectedWebView != nil && currentSelectedSpaceIndex == selectedSpaceIndex && selectedSpaceIndex >= 0 && selectedSpaceIndex < spaces.count && !newUrl.isEmpty {
                            let tabIndex = manager.selectedTabIndex
                            if manager.selectedTabLocation == .pinned {
                                if tabIndex >= 0 && tabIndex < spaces[selectedSpaceIndex].pinnedUrls.count {
                                    spaces[selectedSpaceIndex].pinnedUrls[tabIndex] = newUrl
                                }
                            }
                            else if manager.selectedTabLocation == .tabs {
                                if tabIndex >= 0 && tabIndex < spaces[selectedSpaceIndex].tabUrls.count {
                                    spaces[selectedSpaceIndex].tabUrls[tabIndex] = newUrl
                                }
                            }
                            else if manager.selectedTabLocation == .favorites {
                                if tabIndex >= 0 && tabIndex < spaces[selectedSpaceIndex].favoritesUrls.count {
                                    spaces[selectedSpaceIndex].favoritesUrls[tabIndex] = newUrl
                                }
                            }

                            if settings.historyEnabled && !newUrl.starts(with: "aura://") && variables.history.items.first?.websiteURL != newUrl {
                                variables.history.addItem(HistoryItem(title: manager.linksWithTitles[newUrl], websiteURL: newUrl, date: Date.now))
                            }
                        }

                        if selectedSpaceIndex >= 0 && selectedSpaceIndex < spaces.count {
                            let fetchTitlesArrays = spaces[selectedSpaceIndex].tabUrls + spaces[selectedSpaceIndex].pinnedUrls + spaces[selectedSpaceIndex].favoritesUrls

                            manager.fetchTitlesIfNeeded(for: fetchTitlesArrays)
                        }
                    })
                }
            
            SpacePicker(currentSpace: $currentSpace, selectedSpaceIndex: $selectedSpaceIndex)
                .frame(minWidth: 44, idealWidth: 96, maxWidth: 132)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Spacer()
                        .frame(width: 10)
                    
                    SpaceCustomizationButton(space: spaces[currentSelectedSpaceIndex])
                        .frame(width: 180)
                    
                    ForEach(spaces[currentSelectedSpaceIndex].favoritesUrls.indices, id: \.self) { tabIndex in
                        VStack {
                            if tabIndex < draggedItemIndex ?? 0 {
                                if currentHoverIndex == tabIndex && manager.dragTabLocation == .favorites {
                                    HStack(spacing: 0) {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(height: 8)
                                        
                                        Color.primary
                                            .frame(height: 2)
                                            .cornerRadius(10)
                                            .offset(x: -2)
                                    }.padding(.horizontal, 10)
                                }
                            }
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primary.opacity(0.15), lineWidth: settings.favoriteTabBorderWidth)
                                    .fill(Color.primary.opacity((tabIndex == manager.selectedTabIndex && manager.selectedTabLocation == .favorites) ? 0.14 : (manager.hoverTabIndex == tabIndex && manager.hoverTabLocation == .favorites) ? 0.08 : 0.04))
                                    .frame(height: 50)
                                
                                HStack {
                                    if !favoritesStyle {
                                        if faviconLoadingStyle {
                                            WebImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex])&sz=\(128)".replacingOccurrences(of: "https://www.google.com/s2/favicons?domain=Optional(", with: "https://www.google.com/s2/favicons?domain=").replacingOccurrences(of: ")&sz=", with: "&sz=").replacingOccurrences(of: "\"", with: ""))) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 25, height: 25)
                                                    .cornerRadius(faviconShape == "square" ? 0: faviconShape == "squircle" ? 5: 100)
                                                    .padding(10)
                                                
                                            } placeholder: {
                                                LoadingAnimations(size: 25, borderWidth: 5.0)
                                                    .padding(10)
                                            }
                                            .onSuccess { image, data, cacheType in
                                                
                                            }
                                            .indicator(.activity)
                                            .transition(.fade(duration: 0.5))
                                            .scaledToFit()
                                            
                                        } else {
                                            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex])&sz=\(128)".replacingOccurrences(of: "https://www.google.com/s2/favicons?domain=Optional(", with: "https://www.google.com/s2/favicons?domain=").replacingOccurrences(of: ")&sz=", with: "&sz=").replacingOccurrences(of: "\"", with: ""))) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 25, height: 25)
                                                    .cornerRadius(faviconShape == "square" ? 0: faviconShape == "squircle" ? 5: 100)
                                                    .padding(10)
                                                
                                            } placeholder: {
                                                LoadingAnimations(size: 25, borderWidth: 5.0)
                                                    .padding(10)
                                            }
                                        }
                                    }
                                    else {
                                        Text(manager.linksWithTitles[spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex]] ?? spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex])
                                            .lineLimit(1)
                                            .foregroundStyle(.primary)
                                            .padding(.leading, 5)
                                    }
                                }
                            }
                            .contextMenu {
                                if !settings.hideBrowseForMe {
                                    Button {
                                        variables.browseForMeSearch = spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex]
                                        variables.isBrowseForMe = true
                                    } label: {
                                        Label("Browse for Me", systemImage: "globe.desk")
                                    }
                                }
#if !os(macOS)
                                Button {
                                    UIPasteboard.general.string = spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex]
                                } label: {
                                    Label("Copy URL", systemImage: "link")
                                }
#endif
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].favoritesUrls
                                    temporaryUrls.insert(spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex], at: tabIndex + 1)
                                    
                                    spaces[currentSelectedSpaceIndex].pinnedUrls = temporaryUrls
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].pinnedUrls
                                    temporaryUrls.append(spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex])
                                    
                                    spaces[currentSelectedSpaceIndex].pinnedUrls = temporaryUrls
                                    
                                    favoriteRemoveTab(at: tabIndex)
                                    
                                } label: {
                                    Label("Pin", systemImage: "pin.fill")
                                }
                                
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].tabUrls
                                    temporaryUrls.append(spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex])
                                    
                                    spaces[currentSelectedSpaceIndex].tabUrls = temporaryUrls
                                    
                                    favoriteRemoveTab(at: tabIndex)
                                    
                                } label: {
                                    Label("Unfavorite", systemImage: "star")
                                }
                                
                                Button {
                                    favoriteRemoveTab(at: tabIndex)
                                } label: {
                                    Label("Close Tab", systemImage: "xmark")
                                }
                                
                            }
                            .onHover(perform: { hovering in
                                if hovering {
                                    manager.hoverTabIndex = tabIndex
                                    manager.hoverTabLocation = .favorites
                                }
                                else {
                                    manager.hoverTabIndex = -1
                                }
                            })
                            .onTapGesture {
                                manager.selectedTabIndex = tabIndex
                                
                                manager.selectedTabLocation = .favorites
                                
                                manager.selectOrAddWebView(urlString: spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex])
                                
                                variables.searchInSidebar = unformatURL(url: spaces[currentSelectedSpaceIndex].favoritesUrls[tabIndex])
                            }
                            .onDrag {
                                draggedItem = spaces[selectedSpaceIndex].favoritesUrls[tabIndex]
                                draggedItemIndex = tabIndex
                                reorderingTabs = spaces[selectedSpaceIndex].favoritesUrls
                                
                                manager.dragTabLocation = .favorites
                                
                                //currentHoverIndex = -1
                                
                                return NSItemProvider(object: spaces[selectedSpaceIndex].favoritesUrls[tabIndex] as NSString)
                            }
                            
                            if tabIndex > draggedItemIndex ?? 0 {
                                //if tabIndex != draggedItemIndex {
                                if currentHoverIndex == tabIndex && manager.dragTabLocation == .favorites {
                                    HStack(spacing: 0) {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(height: 8)
                                        
                                        Color.primary
                                            .frame(height: 2)
                                            .cornerRadius(10)
                                            .offset(x: -2)
                                    }.padding(.horizontal, 10)
                                }
                            }
                        }
                        .background(
                            Color.white.opacity(0.0001)
                        )
                        .onDrop(of: [.text], delegate: IndexDropViewDelegate(
                            destinationIndex: tabIndex,
                            allItems: $reorderingTabs,
                            draggedItem: $draggedItem,
                            draggedItemIndex: $draggedItemIndex,
                            currentHoverIndex: $currentHoverIndex,
                            onDropAction: {
                                withAnimation {
                                    spaces[selectedSpaceIndex].favoritesUrls = reorderingTabs
                                }
                                currentHoverIndex = -1
                            }
                        ))                    }
                    .onAppear() {
                        manager.fetchTitles(for: spaces[currentSelectedSpaceIndex].favoritesUrls)
                    }
                    
                    Color.primary
                        .opacity(0.5)
                        .frame(width: 1, height: 40)
                        .cornerRadius(10)
                    
                    ForEach(spaces[currentSelectedSpaceIndex].pinnedUrls.indices, id: \.self) { tabIndex in
                        VStack {
                            if tabIndex < draggedItemIndex ?? 0 {
                                if currentHoverIndex == tabIndex && manager.dragTabLocation == .pinned {
                                    HStack(spacing: 0) {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(height: 8)
                                        
                                        Color.primary
                                            .frame(height: 2)
                                            .cornerRadius(10)
                                            .offset(x: -2)
                                    }.padding(.horizontal, 10)
                                }
                            }
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                                    .fill(Color.primary.opacity((tabIndex == manager.selectedTabIndex && manager.selectedTabLocation == .pinned) ? 0.12 : (manager.hoverTabIndex == tabIndex && manager.hoverTabLocation == .pinned) ? 0.08 : 0.04))
                                    .frame(height: 50)
                                
                                HStack {
                                    if faviconLoadingStyle {
                                        WebImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex])&sz=\(128)".replacingOccurrences(of: "https://www.google.com/s2/favicons?domain=Optional(", with: "https://www.google.com/s2/favicons?domain=").replacingOccurrences(of: ")&sz=", with: "&sz=").replacingOccurrences(of: "\"", with: ""))) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                                .cornerRadius(faviconShape == "square" ? 0: faviconShape == "squircle" ? 5: 100)
                                                .padding(.leading, 5)
                                            
                                        } placeholder: {
                                            LoadingAnimations(size: 25, borderWidth: 5.0)
                                                .padding(.leading, 5)
                                        }
                                        .onSuccess { image, data, cacheType in
                                            
                                        }
                                        .indicator(.activity)
                                        .transition(.fade(duration: 0.5))
                                        .scaledToFit()
                                        
                                    } else {
                                        AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex])&sz=\(128)".replacingOccurrences(of: "https://www.google.com/s2/favicons?domain=Optional(", with: "https://www.google.com/s2/favicons?domain=").replacingOccurrences(of: ")&sz=", with: "&sz=").replacingOccurrences(of: "\"", with: ""))) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                                .cornerRadius(faviconShape == "square" ? 0: faviconShape == "squircle" ? 5: 100)
                                                .padding(.leading, 5)
                                            
                                        } placeholder: {
                                            LoadingAnimations(size: 25, borderWidth: 5.0)
                                                .padding(.leading, 5)
                                        }
                                    }
                                    
                                    
                                    Text(manager.linksWithTitles[spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex]] ?? spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex])
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)
                                        .padding(.leading, 5)
                                        .frame(maxWidth: 150)
                                        .clipped()
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        pinnedRemoveTab(at: tabIndex)
                                    }) {
                                        if (manager.hoverTabIndex == tabIndex && manager.hoverTabLocation == .pinned) || (manager.selectedTabLocation == .pinned && manager.selectedTabIndex  == tabIndex) {
                                            ZStack {
#if !os(visionOS)
                                                Color(.white)
                                                    .opacity(manager.hoverCloseTabIndex == tabIndex ? 0.3: 0.0)
#endif
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 15, height: 15)
                                                    .foregroundStyle(.primary)
                                                    .opacity(manager.hoverCloseTabIndex == tabIndex ? 1.0: 0.8)
                                                
                                            }.frame(width: 35, height: 35)
                                                .onHover(perform: { hovering in
                                                    if hovering {
                                                        manager.hoverCloseTabIndex = tabIndex
                                                        manager.hoverTabLocation = .pinned
                                                    }
                                                    else {
                                                        manager.hoverCloseTabIndex = -1
                                                    }
                                                })
#if !os(visionOS) && !os(macOS)
                                                .cornerRadius(7)
                                                .padding(.trailing, 10)
                                                //.hoverEffect(.lift)
#endif
                                            
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }
                            .contextMenu {
                                if !settings.hideBrowseForMe {
                                    Button {
                                        variables.browseForMeSearch = spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex]
                                        variables.isBrowseForMe = true
                                    } label: {
                                        Label("Browse for Me", systemImage: "globe.desk")
                                    }
                                }
#if !os(macOS)
                                Button {
                                    UIPasteboard.general.string = spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex]
                                } label: {
                                    Label("Copy URL", systemImage: "link")
                                }
#endif
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].pinnedUrls
                                    temporaryUrls.insert(spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex], at: tabIndex + 1)
                                    
                                    spaces[currentSelectedSpaceIndex].pinnedUrls = temporaryUrls
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].tabUrls
                                    temporaryUrls.append(spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex])
                                    
                                    spaces[currentSelectedSpaceIndex].tabUrls = temporaryUrls
                                    
                                    pinnedRemoveTab(at: tabIndex)
                                    
                                } label: {
                                    Label("Unpin", systemImage: "pin.fill")
                                }
                                
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].favoritesUrls
                                    temporaryUrls.append(spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex])
                                    
                                    spaces[currentSelectedSpaceIndex].favoritesUrls = temporaryUrls
                                    
                                    pinnedRemoveTab(at: tabIndex)
                                    
                                } label: {
                                    Label("Favorite", systemImage: "star")
                                }
                                
                                Button {
                                    pinnedRemoveTab(at: tabIndex)
                                } label: {
                                    Label("Close Tab", systemImage: "xmark")
                                }
                                
                            }
                            .onHover(perform: { hovering in
                                withAnimation {
                                    if hovering {
                                        manager.hoverTabIndex = tabIndex
                                        manager.hoverTabLocation = .pinned
                                    }
                                    else {
                                        manager.hoverTabIndex = -1
                                    }
                                }
                            })
                            .onTapGesture {
                                manager.selectedTabIndex = tabIndex
                                
                                manager.selectedTabLocation = .pinned
                                
                                manager.selectOrAddWebView(urlString: spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex])
                                
                                variables.searchInSidebar = unformatURL(url: spaces[currentSelectedSpaceIndex].pinnedUrls[tabIndex])
                            }
                            .onDrag {
                                draggedItem = spaces[selectedSpaceIndex].pinnedUrls[tabIndex]
                                draggedItemIndex = tabIndex
                                reorderingTabs = spaces[selectedSpaceIndex].pinnedUrls
                                
                                manager.dragTabLocation = .pinned
                                
                                //currentHoverIndex = -1
                                
                                return NSItemProvider(object: spaces[selectedSpaceIndex].pinnedUrls[tabIndex] as NSString)
                            }
                            
                            if tabIndex > draggedItemIndex ?? 0 {
                                //if tabIndex != draggedItemIndex {
                                if currentHoverIndex == tabIndex && manager.dragTabLocation == .pinned {
                                    HStack(spacing: 0) {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(height: 8)
                                        
                                        Color.primary
                                            .frame(height: 2)
                                            .cornerRadius(10)
                                            .offset(x: -2)
                                    }.padding(.horizontal, 10)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .background(
                            Color.white.opacity(0.0001)
                        )
                        .onDrop(of: [.text], delegate: IndexDropViewDelegate(
                            destinationIndex: tabIndex,
                            allItems: $reorderingTabs,
                            draggedItem: $draggedItem,
                            draggedItemIndex: $draggedItemIndex,
                            currentHoverIndex: $currentHoverIndex,
                            onDropAction: {
                                withAnimation {
                                    spaces[selectedSpaceIndex].pinnedUrls = reorderingTabs
                                }
                                currentHoverIndex = -1
                            }
                        ))                    }
                    .onAppear() {
                        manager.fetchTitles(for: spaces[currentSelectedSpaceIndex].pinnedUrls)
                    }
                    
                    ForEach(Array(stride(from: spaces[currentSelectedSpaceIndex].tabUrls.count-1, through: 0, by: -1)), id: \.self) { tabIndex in
                        //ForEach(0..<spaces[currentSelectedSpaceIndex].tabUrls.count, id: \.self) { tabIndex in
                        VStack {
                            
                            if tabIndex > draggedItemIndex ?? 0 {
                                if currentHoverIndex == tabIndex && manager.dragTabLocation == .tabs {
                                    HStack(spacing: 0) {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(height: 8)
                                        
                                        Color.primary
                                            .frame(height: 2)
                                            .cornerRadius(10)
                                            .offset(x: -2)
                                    }.padding(.horizontal, 10)
                                }
                            }
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                                    .fill(Color.primary.opacity((tabIndex == manager.selectedTabIndex && manager.selectedTabLocation == .tabs) ? 0.12 : (manager.hoverTabIndex == tabIndex && manager.hoverTabLocation == .tabs) ? 0.08 : 0.04))
                                    .frame(height: 50)
                                
                                HStack {
                                    if faviconLoadingStyle {
                                        WebImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(spaces[currentSelectedSpaceIndex].tabUrls[tabIndex])&sz=\(128)".replacingOccurrences(of: "https://www.google.com/s2/favicons?domain=Optional(", with: "https://www.google.com/s2/favicons?domain=").replacingOccurrences(of: ")&sz=", with: "&sz=").replacingOccurrences(of: "\"", with: ""))) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                                .cornerRadius(faviconShape == "square" ? 0: faviconShape == "squircle" ? 5: 100)
                                                .padding(.leading, 5)
                                            
                                        } placeholder: {
                                            LoadingAnimations(size: 25, borderWidth: 5.0)
                                                .padding(.leading, 5)
                                        }
                                        .onSuccess { image, data, cacheType in
                                            
                                        }
                                        .indicator(.activity)
                                        .transition(.fade(duration: 0.5))
                                        .scaledToFit()
                                        
                                    } else {
                                        AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(spaces[currentSelectedSpaceIndex].tabUrls[tabIndex])&sz=\(128)".replacingOccurrences(of: "https://www.google.com/s2/favicons?domain=Optional(", with: "https://www.google.com/s2/favicons?domain=").replacingOccurrences(of: ")&sz=", with: "&sz=").replacingOccurrences(of: "\"", with: ""))) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                                .cornerRadius(faviconShape == "square" ? 0: faviconShape == "squircle" ? 5: 100)
                                                .padding(.leading, 5)
                                            
                                        } placeholder: {
                                            LoadingAnimations(size: 25, borderWidth: 5.0)
                                                .padding(.leading, 5)
                                        }
                                    }
                                    
                                    
                                    Text(manager.linksWithTitles[spaces[currentSelectedSpaceIndex].tabUrls[tabIndex]] ?? spaces[currentSelectedSpaceIndex].tabUrls[tabIndex])
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)
                                        .padding(.leading, 5)
                                        .frame(maxWidth: 150)
                                        .clipped()
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        removeTab(at: tabIndex)
                                    }) {
                                        if (manager.hoverTabIndex == tabIndex && manager.hoverTabLocation == .tabs) || (manager.selectedTabLocation == .tabs && manager.selectedTabIndex  == tabIndex) {
                                            ZStack {
#if !os(visionOS)
                                                Color(.white)
                                                    .opacity(manager.hoverCloseTabIndex == tabIndex ? 0.3: 0.0)
#endif
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 15, height: 15)
                                                    .foregroundStyle(.primary)
                                                    .opacity(manager.hoverCloseTabIndex == tabIndex ? 1.0: 0.8)
                                                
                                            }.frame(width: 35, height: 35)
                                                .onHover(perform: { hovering in
                                                    if hovering {
                                                        manager.hoverCloseTabIndex = tabIndex
                                                        manager.hoverTabLocation = .tabs
                                                    }
                                                    else {
                                                        manager.hoverCloseTabIndex = -1
                                                    }
                                                })
#if !os(visionOS) && !os(macOS)
                                                .cornerRadius(7)
                                                .padding(.trailing, 10)
                                                //.hoverEffect(.lift)
#endif
                                            
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }
                            .contextMenu {
                                if !settings.hideBrowseForMe {
                                    Button {
                                        variables.browseForMeSearch = spaces[currentSelectedSpaceIndex].tabUrls[tabIndex]
                                        variables.isBrowseForMe = true
                                    } label: {
                                        Label("Browse for Me", systemImage: "globe.desk")
                                    }
                                }
#if !os(macOS)
                                Button {
                                    UIPasteboard.general.string = spaces[currentSelectedSpaceIndex].tabUrls[tabIndex]
                                } label: {
                                    Label("Copy URL", systemImage: "link")
                                }
#endif
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].tabUrls
                                    temporaryUrls.insert(spaces[currentSelectedSpaceIndex].tabUrls[tabIndex], at: tabIndex + 1)
                                    
                                    spaces[currentSelectedSpaceIndex].tabUrls = temporaryUrls
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].pinnedUrls
                                    temporaryUrls.append(spaces[currentSelectedSpaceIndex].tabUrls[tabIndex])
                                    
                                    spaces[currentSelectedSpaceIndex].pinnedUrls = temporaryUrls
                                    
                                    removeTab(at: tabIndex)
                                    
                                } label: {
                                    Label("Pin", systemImage: "pin.fill")
                                }
                                
                                Button {
                                    var temporaryUrls = spaces[currentSelectedSpaceIndex].favoritesUrls
                                    temporaryUrls.append(spaces[currentSelectedSpaceIndex].tabUrls[tabIndex])
                                    
                                    spaces[currentSelectedSpaceIndex].favoritesUrls = temporaryUrls
                                    
                                    removeTab(at: tabIndex)
                                    
                                } label: {
                                    Label("Favorite", systemImage: "star")
                                }
                                
                                Button {
                                    removeTab(at: tabIndex)
                                } label: {
                                    Label("Close Tab", systemImage: "xmark")
                                }
                                
                            }
                            .onHover(perform: { hovering in
                                withAnimation {
                                    if hovering {
                                        manager.hoverTabIndex = tabIndex
                                        manager.hoverTabLocation = .tabs
                                    }
                                    else {
                                        manager.hoverTabIndex = -1
                                    }
                                }
                            })
                            .onTapGesture {
                                manager.selectedTabIndex = tabIndex
                                
                                manager.selectedTabLocation = .tabs
                                
                                manager.selectOrAddWebView(urlString: spaces[currentSelectedSpaceIndex].tabUrls[tabIndex])
                                
                                variables.searchInSidebar = unformatURL(url: spaces[currentSelectedSpaceIndex].tabUrls[tabIndex])
                            }
                            .onDrag {
                                draggedItem = spaces[selectedSpaceIndex].tabUrls[tabIndex]
                                draggedItemIndex = tabIndex
                                reorderingTabs = spaces[selectedSpaceIndex].tabUrls
                                
                                manager.dragTabLocation = .tabs
                                
                                //currentHoverIndex = -1
                                
                                return NSItemProvider(object: spaces[selectedSpaceIndex].tabUrls[tabIndex] as NSString)
                            }
                            
                            if tabIndex < draggedItemIndex ?? 0 {
                                //if tabIndex != draggedItemIndex {
                                if currentHoverIndex == tabIndex && manager.dragTabLocation == .tabs {
                                    HStack(spacing: 0) {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(height: 8)
                                        
                                        Color.primary
                                            .frame(height: 2)
                                            .cornerRadius(10)
                                            .offset(x: -2)
                                    }.padding(.horizontal, 10)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .background(
                            Color.white.opacity(0.0001)
                        )
                        .onDrop(of: [.text], delegate: IndexDropViewDelegate(
                            destinationIndex: tabIndex,
                            allItems: $reorderingTabs,
                            draggedItem: $draggedItem,
                            draggedItemIndex: $draggedItemIndex,
                            currentHoverIndex: $currentHoverIndex,
                            onDropAction: {
                                withAnimation {
                                    spaces[selectedSpaceIndex].tabUrls = reorderingTabs
                                }
                                currentHoverIndex = -1
                            }
                        ))
                    }
                    .onAppear() {
                        manager.fetchTitles(for: spaces[currentSelectedSpaceIndex].tabUrls)
                    }
                }
                
                
            }
            
            Button {
                variables.showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 7)
    }
    
    func favoriteRemoveTab(at index: Int) {
        guard currentSelectedSpaceIndex >= 0 && currentSelectedSpaceIndex < spaces.count else { return }
        var temporaryUrls = spaces[currentSelectedSpaceIndex].favoritesUrls
        guard index >= 0 && index < temporaryUrls.count else { return }

        let wasSelected = index == manager.selectedTabIndex && manager.selectedTabLocation == .favorites
        temporaryUrls.remove(at: index)
        spaces[currentSelectedSpaceIndex].favoritesUrls = temporaryUrls

        if wasSelected {
            if temporaryUrls.isEmpty {
                manager.selectedWebView = nil
                manager.selectedTabIndex = -1
                variables.searchInSidebar = ""
            } else {
                let newIndex = min(index, temporaryUrls.count - 1)
                manager.selectedTabIndex = newIndex
                manager.selectOrAddWebView(urlString: temporaryUrls[newIndex])
                variables.searchInSidebar = unformatURL(url: temporaryUrls[newIndex])
            }
        } else if manager.selectedTabLocation == .favorites && index < manager.selectedTabIndex {
            manager.selectedTabIndex -= 1
        }

        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    func pinnedRemoveTab(at index: Int) {
        guard currentSelectedSpaceIndex >= 0 && currentSelectedSpaceIndex < spaces.count else { return }
        var temporaryUrls = spaces[currentSelectedSpaceIndex].pinnedUrls
        guard index >= 0 && index < temporaryUrls.count else { return }

        let wasSelected = index == manager.selectedTabIndex && manager.selectedTabLocation == .pinned
        temporaryUrls.remove(at: index)
        spaces[currentSelectedSpaceIndex].pinnedUrls = temporaryUrls

        if wasSelected {
            if temporaryUrls.isEmpty {
                manager.selectedWebView = nil
                manager.selectedTabIndex = -1
                variables.searchInSidebar = ""
            } else {
                let newIndex = min(index, temporaryUrls.count - 1)
                manager.selectedTabIndex = newIndex
                manager.selectOrAddWebView(urlString: temporaryUrls[newIndex])
                variables.searchInSidebar = unformatURL(url: temporaryUrls[newIndex])
            }
        } else if manager.selectedTabLocation == .pinned && index < manager.selectedTabIndex {
            manager.selectedTabIndex -= 1
        }

        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    func removeTab(at index: Int) {
        guard currentSelectedSpaceIndex >= 0 && currentSelectedSpaceIndex < spaces.count else { return }
        var temporaryUrls = spaces[currentSelectedSpaceIndex].tabUrls
        guard index >= 0 && index < temporaryUrls.count else { return }

        let wasSelected = index == manager.selectedTabIndex && manager.selectedTabLocation == .tabs
        temporaryUrls.remove(at: index)
        spaces[currentSelectedSpaceIndex].tabUrls = temporaryUrls

        if wasSelected {
            if temporaryUrls.isEmpty {
                manager.selectedWebView = nil
                manager.selectedTabIndex = -1
                variables.searchInSidebar = ""
            } else {
                let newIndex = min(index, temporaryUrls.count - 1)
                manager.selectedTabIndex = newIndex
                manager.selectOrAddWebView(urlString: temporaryUrls[newIndex])
                variables.searchInSidebar = unformatURL(url: temporaryUrls[newIndex])
            }
        } else if manager.selectedTabLocation == .tabs && index < manager.selectedTabIndex {
            manager.selectedTabIndex -= 1
        }

        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}
