//
//  TestingView.swift
//  iPad browser
//
//  Created by Reyna Myers on 8/9/23.
//

import SwiftUI
import UIKit
import WebKit
import Combine
import SDWebImage
import SDWebImageSwiftUI
import SwiftData
import CodeEditor


let defaults = UserDefaults.standard


struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @Environment(\.modelContext) var modelContext
    @Query(sort: \SpaceStorage.spaceIndex) var spaces: [SpaceStorage]
    
    @EnvironmentObject var variables: ObservableVariables
    @EnvironmentObject var settings: SettingsVariables
    @StateObject private var boostStore = BoostStore()
    
    @EnvironmentObject var manager: WebsiteManager
    
    @AppStorage("currentSpace") var currentSpace = "Untitled"
    
    @AppStorage("startColorHex") var startHex = "8A3CEF"
    @AppStorage("endColorHex") var endHex = "84F5FE"
    
    @State var boostEditor = true
    @State var currentBoostText = ""
    @State var currentPassedClassesString = ""
    @State var generateAICSS = false
    
    
    @AppStorage("hideSidebar") var hideSidebar = false
    
    
    @FocusState private var focusedField: FocusedField?
    
    @AppStorage("selectedSpaceIndex") var selectedSpaceIndex = 0
    
    enum FocusedField {
        case commandBar, tabBar, none
    }
    
    @State var launchingAnimation = true
    
    @State var changingBoost = false
    @State var boostWindowWidth: CGFloat = 300.0
    @State var webInspectorHeight: CGFloat = 300.0
    
    @State var inspectCodeString = ""
    @State var customAIBoostInstructions = ""
    
    @State var cssTimeout = false
    
    @State var inspectorTab = 0
    
    @State var aiGenerationPopover = false
    
    @State var htmlInspectTimeoutCounter = 0
    
    var body: some View {
        ZStack {
            shellBackground.ignoresSafeArea()
            
            if UIDevice.current.userInterfaceIdiom != .phone {
                GeometryReader { geo in
                    if spaces.count > 0 {
                        ZStack {
                            ZStack {
                                VStack(spacing: 0) {
                                    if settings.horizontalTabBar {
                                        HorizontalSidebar(currentSelectedSpaceIndex: manager.selectedSpaceIndex, geo: geo)
                                            .frame(height: 100)
                                    }
                                    
                                    HStack(spacing: 0) {
#if !os(visionOS)
                                        if settings.sidebarLeft && !settings.horizontalTabBar && !hideSidebar {
                                            //PagedSidebar(fullGeo: geo)
                                            TabbedPagedSidebar(isHovering: false)
                                                .padding(5)
                                                .padding(.leading, 5)
                                        }
                                        #endif
                                        HStack {
                                            GeometryReader { webGeo in
                                                ZStack {
                                                    Color(uiColor: .systemBackground)
                                                        .cornerRadius(12)
                                                    
                                                    
                                                    //MARK: - WebView
                                                    CurrentWebView(webGeo: webGeo)
                                                    
                                                    if !settings.swipeNavigationDisabled {
                                                        if manager.selectedWebView != nil {
                                                            HStack(alignment: .center, spacing: 0) {
                                                                navigationButton(imageName: "arrow.left", action: {
                                                                    manager.selectedWebView?.webView.goBack()
                                                                })
                                                                .padding(.trailing, 30)
                                                                
                                                                Spacer()
                                                                    .frame(width: webGeo.size.width)
                                                                
                                                                navigationButton(imageName: "arrow.right", action: {
                                                                    manager.selectedWebView?.webView.goForward()
                                                                })
                                                                .padding(.leading, 30)
                                                                
                                                            }
                                                            .frame(width: webGeo.size.width)
                                                            .offset(x: variables.navigationOffset)
                                                        }
                                                    }
                                                    
                                                    if variables.auraTab == "dashboard" && manager.selectedWebView == nil {
                                                        Dashboard(startHexSpace: selectedSpaceIndex < spaces.count ? spaces[selectedSpaceIndex].startHex : startHex, endHexSpace: selectedSpaceIndex < spaces.count ? spaces[selectedSpaceIndex].endHex : endHex)
                                                            .cornerRadius(10)
                                                            .clipped()
                                                    }
                                                    
                                                    if variables.auraTab == "history" && manager.selectedWebView == nil {
                                                        HistoryView()
                                                            .environmentObject(variables.history)
                                                            .cornerRadius(10)
                                                            .clipped()
                                                    }
                                                    
                                                    Spacer()
                                                        .frame(width: 20)
                                                    
                                                    HStack {
                                                        Button {
                                                            Task {
                                                                hideSidebar.toggle()
                                                            }
                                                        } label: {
                                                            
                                                        }
                                                        .keyboardShortcut(variables.shortcuts.parseShortcut(shortcut: variables.shortcuts.toggleSidebar))
                                                        .buttonStyle(.plain)
                                                        
                                                        Button {
                                                            if manager.selectedWebView?.webView.canGoBack ?? true {
                                                                manager.selectedWebView?.webView.goBack()
                                                            }
                                                        } label: {
                                                            
                                                        }
                                                        .keyboardShortcut(variables.shortcuts.parseShortcut(shortcut: variables.shortcuts.goBack))
                                                        .buttonStyle(.plain)
                                                        
                                                        Button {
                                                            if manager.selectedWebView?.webView.canGoForward ?? true {
                                                                manager.selectedWebView?.webView.goForward()
                                                            }
                                                        } label: {
                                                            
                                                        }
                                                        .keyboardShortcut(variables.shortcuts.parseShortcut(shortcut: variables.shortcuts.goForward))
                                                        .buttonStyle(.plain)
                                                        
                                                        Button {
                                                            variables.showSettings = true
                                                        } label: {
                                                            
                                                        }
                                                        .keyboardShortcut(",", modifiers: [.command])
                                                        .buttonStyle(.plain)
                                                        
                                                        
                                                        Button {
                                                            variables.searchInSidebar = manager.selectedWebView?.webView.url?.absoluteString ?? variables.searchInSidebar
                                                            manager.selectedWebView?.reload()
                                                            
                                                            if let urlString = manager.selectedWebView?.webView.url?.absoluteString,
                                                               let key = unformatPlainURL(url: urlString).components(separatedBy: "/").first {
                                                                
                                                                print("Text Changed:")
                                                                print("Key: \(key)")
                                                                print("Updated Text: \(currentBoostText)")
                                                                
                                                                variables.boosts.keyValuePairs[key] = currentBoostText
                                                                
                                                                let jsToInjectCSS = """
                                                    (function() {
                                                      var style = document.createElement('style');
                                                      style.textContent = `\(currentBoostText)`;
                                                      document.head.appendChild(style);
                                                    })();
                                                    """
                                                                if !variables.boosts.disabledBoosts.contains(key) {
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + settings.jsInjectionDelayBoosts) {
                                                                        manager.selectedWebView?.JSperformScript(script: jsToInjectCSS)
                                                                    }
                                                                }
                                                            }
                                                            
                                                        } label: {
                                                            
                                                        }
                                                        .keyboardShortcut(variables.shortcuts.parseShortcut(shortcut: variables.shortcuts.reload))
                                                        .buttonStyle(.plain)
                                                        
                                                        
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
                                                            
                                                        }
                                                        .keyboardShortcut(variables.shortcuts.parseShortcut(shortcut: variables.shortcuts.commandBar))
                                                        .buttonStyle(.plain)
                                                        
                                                        
                                                        Button {
                                                            if manager.selectedWebView != nil {
                                                                switch manager.selectedTabLocation {
                                                                case .pinned:
                                                                    pinnedRemoveTab(at: manager.selectedTabIndex)
                                                                case .favorites:
                                                                    favoriteRemoveTab(at: manager.selectedTabIndex)
                                                                case .tabs:
                                                                    removeTab(at: manager.selectedTabIndex)
                                                                }
                                                            }
                                                        } label: {
                                                            
                                                        }.keyboardShortcut("w", modifiers: .command)
                                                            .buttonStyle(.plain)
                                                        
                                                        
                                                        Button {
                                                            variables.tabBarShown.toggle()
                                                            variables.commandBarShown = false
                                                        } label: {
                                                            
                                                        }
                                                        .keyboardShortcut(variables.shortcuts.parseShortcut(shortcut: variables.shortcuts.newTab))
                                                        .buttonStyle(.plain)
                                                        
                                                        
                                                    }
                                                }
                                                .gesture(
                                                    DragGesture()
                                                        .onChanged { value in
                                                            if !settings.swipeNavigationDisabled {
                                                                let startLocation = value.startLocation.x
                                                                let width = webGeo.size.width
                                                                
                                                                if startLocation < 100 || startLocation > (width - 100) {
                                                                    let newOffset = value.translation.width
                                                                    if abs(newOffset) <= 150 {
                                                                        variables.navigationOffset = newOffset
                                                                    } else {
                                                                        variables.navigationOffset = newOffset > 0 ? 150 : -150
                                                                    }
                                                                    if abs(newOffset) > 100 {
                                                                        if !variables.arrowImpactOnce {
                                                                            heavyHaptics()
                                                                            
                                                                            variables.arrowImpactOnce = true
                                                                        }
                                                                        
                                                                        withAnimation(.linear(duration: 0.3)) {
                                                                            variables.navigationArrowColor = true
                                                                        }
                                                                    } else {
                                                                        if variables.arrowImpactOnce {
                                                                            heavyHaptics()
                                                                            
                                                                            variables.arrowImpactOnce = false
                                                                        }
                                                                        withAnimation(.linear(duration: 0.3)) {
                                                                            variables.navigationArrowColor = false
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .onEnded { value in
                                                            if !settings.swipeNavigationDisabled {
                                                                variables.arrowImpactOnce = false
                                                                let startLocation = value.startLocation.x
                                                                let width = webGeo.size.width
                                                                
                                                                if startLocation < 150 || startLocation > (width - 150) {
                                                                    if variables.navigationOffset >= 100 {
                                                                        goBack()
                                                                    } else if variables.navigationOffset < -100 {
                                                                        goForward()
                                                                    }
                                                                    
                                                                    withAnimation(.linear(duration: 0.25)) {
                                                                        variables.navigationOffset = 0
                                                                        variables.navigationArrowColor = false
                                                                    }
                                                                }
                                                            }
                                                        }
                                                )
                                            }
                                            .cornerRadius(10)
                                            .clipped()
                                            //.padding(settings.sidebarLeft ? .trailing: .leading, settings.showBorder ? 12: 0)
                                            
                                        }
                                        
                                        ZStack {
                                            if variables.boostEditor {
                                                HStack(spacing: 0) {
                                                    VStack {
                                                        Color.black
                                                            .opacity(0.0001)
                                                        
                                                        Color.gray
                                                            .opacity(0.8)
                                                            .cornerRadius(50)
                                                            .frame(height: 30)
                                                            .hoverEffect(.highlight)
                                                            .hoverEffectDisabled(!settings.hoverEffectsAbsorbCursor)
                                                        
                                                        Color.black
                                                            .opacity(0.0001)
                                                        
                                                    }.frame(width: 10)
                                                        .padding(.trailing, 10)
                                                        .gesture(
                                                            DragGesture()
                                                                .onChanged { value in
                                                                    let changedWidth = boostWindowWidth - value.translation.width
                                                                    
                                                                    boostWindowWidth = max(200, changedWidth)
                                                                }
                                                        )
                                                    
                                                    
                                                    VStack {
                                                        ZStack {
                                                            AIBoostGenerator(customInstructions: $customAIBoostInstructions, passedClasses: $currentPassedClassesString, text: $currentBoostText, generate: $generateAICSS)
                                                                .opacity(0.0)
                                                            
                                                            CodeEditor(source: $currentBoostText, language: .css, theme: .agate, fontSize: .constant(15), flags: [.selectable, .editable, .smartIndent], indentStyle: .softTab(width: 4), autoPairs: ["{":"}", "'":"'", "(":")"], allowsUndo: true)
                                                            
                                                            
                                                            
                                                            
                                                            VStack {
                                                                HStack {
                                                                    Spacer()
                                                                    
                                                                    Button {
                                                                        aiGenerationPopover = true
                                                                    } label: {
                                                                        Text("AI")
                                                                    }
#if !os(visionOS)
                                                                    .buttonStyle(PlusButtonStyle())
#endif
                                                                    .padding(15)
                                                                    
                                                                }.popover(isPresented: $aiGenerationPopover, content: {
                                                                    ZStack {
#if !os(visionOS)
                                                                        if selectedSpaceIndex < spaces.count && (!spaces[selectedSpaceIndex].startHex.isEmpty && !spaces[selectedSpaceIndex].endHex.isEmpty) {
                                                                            LinearGradient(colors: [Color(hex: spaces[selectedSpaceIndex].startHex), Color(hex: spaces[selectedSpaceIndex].endHex)], startPoint: .bottomLeading, endPoint: .topTrailing).ignoresSafeArea()
                                                                        }
                                                                        else {
                                                                            LinearGradient(colors: [variables.startColor, variables.endColor], startPoint: .bottomLeading, endPoint: .topTrailing).ignoresSafeArea()
                                                                        }
#endif
                                                                        
                                                                        if settings.prefferedColorScheme == "dark" || (settings.prefferedColorScheme == "automatic" && colorScheme == .dark) {
                                                                            Color.black.opacity(0.5)
                                                                        }
                                                                        
                                                                        VStack {
                                                                            Text("Options")
                                                                            
                                                                            TextField("Custom Instructions", text: $customAIBoostInstructions)
                                                                            
                                                                            Button(action: {
                                                                                print("Style the boost like this \(customAIBoostInstructions). These are your items to style: \(parseHTMLAI(from: removeHeadContent(from: inspectCodeString)).joined(separator: "\n"))")
                                                                                
                                                                                currentPassedClassesString = parseHTMLAI(from: removeHeadContent(from: inspectCodeString)).joined(separator: "\n")
                                                                                
                                                                                print("currentPassedClassesString:")
                                                                                print(currentPassedClassesString)
                                                                                
                                                                                generateAICSS.toggle()
                                                                            }, label: {
                                                                                Text("Generate CSS")
                                                                            })
#if !os(visionOS)
                                                                            .buttonStyle(PlusButtonStyle())
#endif
                                                                        }
                                                                    }
                                                                })
                                                                
                                                                Spacer()
                                                            }
                                                        }
                                                        
                                                        
                                                        HStack {
                                                            Color.black
                                                                .opacity(0.0001)
                                                            
                                                            Color.gray
                                                                .opacity(0.8)
                                                                .cornerRadius(50)
                                                                .frame(width: 30)
                                                                .hoverEffect(.highlight)
                                                                .hoverEffectDisabled(!settings.hoverEffectsAbsorbCursor)
                                                            
                                                            Color.black
                                                                .opacity(0.0001)
                                                            
                                                        }.frame(height: 10)
                                                            .gesture(
                                                                DragGesture()
                                                                    .onChanged { value in
                                                                        let changedHeight = webInspectorHeight - value.translation.height
                                                                        
                                                                        webInspectorHeight = max(100, changedHeight)
                                                                    }
                                                            )
                                                        
                                                        Picker("", selection: $inspectorTab) {
                                                            Text("Inspector").tag(0)
                                                            Text("Classes").tag(1)
                                                        }
                                                        .pickerStyle(.segmented)
                                                        
                                                        if inspectorTab == 0 {
                                                            CodeEditor(source: inspectCodeString, language: .xml, theme: .agate, fontSize: .constant(15), flags: [.selectable, .smartIndent], indentStyle: .softTab(width: 4), allowsUndo: true)
                                                                .frame(height: webInspectorHeight)
                                                        }
                                                        else if inspectorTab == 1 {
                                                            CodeEditor(source: currentPassedClassesString, language: .markdown, theme: .agate, fontSize: .constant(15), flags: [.selectable, .smartIndent], indentStyle: .softTab(width: 4), allowsUndo: true)
                                                                .frame(height: webInspectorHeight)
                                                        }
                                                    }
                                                    .scrollContentBackground(.hidden)
                                                    .tint(.white)
                                                    .frame(width: boostWindowWidth)
                                                }
                                            }
                                        }
                                        .onChange(of: currentBoostText) {
                                            if !cssTimeout {
                                                if let urlString = manager.selectedWebView?.webView.url?.absoluteString,
                                                   let key = unformatPlainURL(url: urlString).components(separatedBy: "/").first {
                                                    
                                                    print("Text Changed:")
                                                    print("Key: \(key)")
                                                    print("Updated Text: \(currentBoostText)")
                                                    
                                                    variables.boosts.keyValuePairs[key] = currentBoostText
                                                    
                                                    let jsToInjectCSS = """
                                        (function() {
                                          var style = document.createElement('style');
                                          style.textContent = `\(currentBoostText)`;
                                          document.head.appendChild(style);
                                        })();
                                        """
                                                    if !variables.boosts.disabledBoosts.contains(key) {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + settings.jsInjectionDelayBoosts) {
                                                            manager.selectedWebView?.JSperformScript(script: jsToInjectCSS)
                                                        }
                                                    }
                                                }
                                                
                                                cssTimeout = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                                cssTimeout = false
                                            })
                                        }
                                        .onChange(of: manager.selectedWebView?.webView.url?.absoluteString ?? "") {
                                            
                                            manager.selectedWebView?.getHTML { thing in
                                                validateHTMLResult(thing: thing ?? "Error")
                                            }
                                            
                                            currentBoostText = ""
                                            
                                            
                                            if let urlString = manager.selectedWebView?.webView.url?.absoluteString,
                                               let key = unformatPlainURL(url: urlString).components(separatedBy: "/").first {
                                                
                                                print("Text Changed:")
                                                print("Key: \(key)")
                                                print("Updated Text: \(currentBoostText)")
                                                
                                                variables.boosts.keyValuePairs[key] = currentBoostText
                                                
                                                let jsToInjectCSS = """
                                        (function() {
                                          var style = document.createElement('style');
                                          style.textContent = `\(currentBoostText)`;
                                          document.head.appendChild(style);
                                        })();
                                        """
                                                if !variables.boosts.disabledBoosts.contains(key) {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + settings.jsInjectionDelayBoosts) {
                                                        manager.selectedWebView?.JSperformScript(script: jsToInjectCSS)
                                                    }
                                                }
                                            }
                                            
                                        }
                                        
                                        if !settings.sidebarLeft && !settings.horizontalTabBar && !hideSidebar {
                                            TabbedPagedSidebar(isHovering: false)
                                        }
                                    }
                                    .onAppear {
                                        if let savedStartColor = getColor(forKey: "startColorHex") {
                                            variables.startColor = savedStartColor
                                        }
                                        if let savedEndColor = getColor(forKey: "endColorHex") {
                                            variables.endColor = savedEndColor
                                        }
                                        
                                        variables.spaceIcons = UserDefaults.standard.dictionary(forKey: "spaceIcons") as? [String: String]
                                    }
                                }//.padding(settings.horizontalTabBar ? [.leading, .trailing, .bottom]: settings.sidebarLeft ? [.trailing, .bottom, .top]: [.leading, .bottom, .top], settings.showBorder ? 20: 0)
                                
                                if variables.tabBarShown || variables.commandBarShown || variables.tapSidebarShown {
                                    Button(action: {
                                        variables.tabBarShown = false
                                        variables.commandBarShown = false
                                        variables.tapSidebarShown = false
                                    }, label: {
                                        Color.white.opacity(0.0001)
                                    }).buttonStyle(.plain)
#if !os(macOS)
                                        .hoverEffectDisabled(true)
#endif
                                }
                                
                                if hideSidebar && !settings.horizontalTabBar {
                                    compactSidebar(availableWidth: geo.size.width)
                                }
                            }
                            .onOpenURL { url in
                                if url.absoluteString.starts(with: "aura://") {
                                    if url.absoluteString.contains("dashboard") {
                                        manager.selectedWebView = nil
                                        variables.auraTab = "dashboard"
                                    }
                                    else if url.absoluteString.contains("history") {
                                        manager.selectedWebView = nil
                                        variables.auraTab = "history"
                                    }
                                    else if url.absoluteString.contains("settings") {
                                        variables.showSettings = true
                                    }
                                }
                                else {
                                    guard !spaces.isEmpty else { return }
                                    let spaceIndex = min(max(selectedSpaceIndex, 0), spaces.count - 1)
                                    let urlString = url.absoluteString

                                    variables.auraTab = ""

                                    var temporaryUrls = spaces[spaceIndex].tabUrls
                                    let tabIndex: Int
                                    if let existingIndex = temporaryUrls.firstIndex(of: urlString) {
                                        tabIndex = existingIndex
                                    } else {
                                        temporaryUrls.append(urlString)
                                        spaces[spaceIndex].tabUrls = temporaryUrls
                                        try? modelContext.save()
                                        tabIndex = temporaryUrls.count - 1
                                    }

                                    manager.selectedTabIndex = tabIndex
                                    manager.selectedTabLocation = .tabs
                                    manager.selectOrAddWebView(urlString: urlString)
                                    variables.searchInSidebar = unformatURL(url: urlString)
                                }
                            }
                            if variables.tabBarShown {
                                CommandBar(commandBarText: $variables.newTabSearch, searchSubmitted: $variables.commandBarSearchSubmitted, collapseHeightAnimation: $variables.commandBarCollapseHeightAnimation, isBrowseForMe: $variables.isBrowseForMe)
                                    .onChange(of: variables.commandBarSearchSubmitted) {
                                        guard variables.commandBarSearchSubmitted else { return }
                                        submitCommand(variables.newTabSearch, inNewTab: true)
                                        variables.commandBarSearchSubmitted = false
                                    }
                            } else if variables.commandBarShown {
                                CommandBar(commandBarText: $variables.searchInSidebar, searchSubmitted: $variables.commandBarSearchSubmitted2, collapseHeightAnimation: $variables.commandBarCollapseHeightAnimation, isBrowseForMe: $variables.isBrowseForMe)
                                    .onChange(of: variables.commandBarSearchSubmitted2) {
                                        guard variables.commandBarSearchSubmitted2 else { return }
                                        submitCommand(variables.searchInSidebar, inNewTab: false)
                                        variables.commandBarSearchSubmitted2 = false
                                    }
                            }
                        }
                        .padding(settings.horizontalTabBar ? [.leading, .trailing, .bottom]: settings.sidebarLeft ? [.trailing, .bottom, .top]: [.leading, .bottom, .top], settings.showBorder ? 20: 0)
                        .onAppear() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.6, execute: {
                                launchingAnimation = false
                            })
                        }
                        .onChange(of: selectedSpaceID) {
                            if variables.initialLoadDone { activateSpace() }
                        }
                        .onAppear {
                            guard !variables.initialLoadDone else { return }
                            selectedSpaceIndex = min(max(UserDefaults.standard.integer(forKey: "savedSelectedSpaceIndex"), 0), max(spaces.count - 1, 0))
                            variables.initialLoadDone = true
                            activateSpace()
                            if settings.commandBarOnLaunch { variables.tabBarShown = true }
                        }
                    }
                }.task {
                    if spaces.count <= 0 {
                        await modelContext.insert(SpaceStorage(spaceIndex: spaces.count, spaceName: "Untitled", spaceIcon: "circle.fill", favoritesUrls: [], pinnedUrls: [], tabUrls: []))
                    }
                }
            }
            else {
                NavigationStack {
                    TabOverview(selectedSpaceIndex: $selectedSpaceIndex)
                }
            }
            
            if launchingAnimation && settings.launchAnimation && !reduceMotion && !settings.reduceMotion {
                Launch_Animation()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
        }
        .foregroundStyle(.primary)
        .environmentObject(variables)
        .environmentObject(manager)
        .environmentObject(settings)
        .transaction { transaction in
            if reduceMotion || settings.reduceMotion {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .overlay(alignment: .trailing) {
            if variables.isBrowseForMe {
                // Stay mounted while a command bar is open so the answer and any
                // in-flight request survive; remounting would resend the prompt.
                let visible = !variables.tabBarShown && !variables.commandBarShown
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        BrowseForMe(searchText: variables.browseForMeSearch, searchResponse: "", closeSheet: $variables.isBrowseForMe)
                            .id(variables.browseForMeSearch)
                            .frame(width: min(420, max(0, geometry.size.width - 24)))
                    }
                    .padding(12)
                }
                .opacity(visible ? 1 : 0)
                .allowsHitTesting(visible)
                .accessibilityHidden(!visible)
            }
        }
        .sheet(isPresented: $variables.showSettings) {
            NewSettings(presentSheet: $variables.showSettings, startHex: activeStartHex, endHex: activeEndHex)
                .environmentObject(settings)
                .environmentObject(variables)
                .environmentObject(manager)
        }
        .onChange(of: hideSidebar) {
            variables.tapSidebarShown = false
            variables.hoveringSidebar = false
        }
        .onChange(of: settings.horizontalTabBar) {
            variables.tapSidebarShown = false
            variables.hoveringSidebar = false
        }
    }

    private var selectedSpaceID: PersistentIdentifier? {
        spaces.indices.contains(selectedSpaceIndex) ? spaces[selectedSpaceIndex].persistentModelID : nil
    }

    private var activeStartHex: String {
        guard spaces.indices.contains(selectedSpaceIndex), !spaces[selectedSpaceIndex].startHex.isEmpty else { return startHex }
        return spaces[selectedSpaceIndex].startHex
    }

    private var activeEndHex: String {
        guard spaces.indices.contains(selectedSpaceIndex), !spaces[selectedSpaceIndex].endHex.isEmpty else { return endHex }
        return spaces[selectedSpaceIndex].endHex
    }

    private var shellBackground: some View {
        LinearGradient(colors: [Color(hex: activeStartHex), Color(hex: activeEndHex)], startPoint: .bottomLeading, endPoint: .topTrailing)
            .overlay(Color(uiColor: .systemBackground).opacity(colorScheme == .dark ? 0.78 : 0.84))
    }

    private func compactSidebar(availableWidth: CGFloat) -> some View {
        let expanded = variables.tapSidebarShown || (!settings.disableSidebarHover && variables.hoveringSidebar)
        return HStack(spacing: 0) {
            if !settings.sidebarLeft { Spacer(minLength: 0) }
            ZStack(alignment: .top) {
                Color.clear
                    .frame(width: expanded ? min(316, max(0, availableWidth - 16)) : 44)
                    .contentShape(Rectangle())
                    .onTapGesture { variables.tapSidebarShown = true }
                    .gesture(DragGesture(minimumDistance: 25).onEnded { value in
                        let inward = settings.sidebarLeft ? value.translation.width : -value.translation.width
                        if inward > 40 && abs(value.translation.width) > abs(value.translation.height) {
                            variables.tapSidebarShown = true
                        }
                    })
                if expanded {
                    TabbedPagedSidebar(isHovering: true)
                        .padding(8)
                        .frame(width: min(316, max(0, availableWidth - 16)))
                        .background {
                            shellBackground
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                        .transition(.opacity)
                } else {
                    Button {
                        variables.tapSidebarShown = true
                    } label: {
                        Image(systemName: "sidebar.left")
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show sidebar")
                }
            }
            .onHover { variables.hoveringSidebar = $0 }
            if settings.sidebarLeft { Spacer(minLength: 0) }
        }
        .padding(8)
        .animation(reduceMotion || settings.reduceMotion ? nil : .easeOut(duration: 0.16), value: expanded)
    }

    private func activateSpace() {
        guard spaces.indices.contains(selectedSpaceIndex) else { return }
        let space = spaces[selectedSpaceIndex]
        currentSpace = space.spaceName
        variables.auraTab = ""
        variables.startColor = Color(hex: activeStartHex)
        variables.endColor = Color(hex: activeEndHex)
        let url: String?
        if let lastTab = space.tabUrls.last {
            manager.selectedTabLocation = .tabs
            manager.selectedTabIndex = space.tabUrls.count - 1
            url = lastTab
        } else if let lastPinned = space.pinnedUrls.last {
            manager.selectedTabLocation = .pinned
            manager.selectedTabIndex = space.pinnedUrls.count - 1
            url = lastPinned
        } else if let firstFavorite = space.favoritesUrls.first {
            manager.selectedTabLocation = .favorites
            manager.selectedTabIndex = 0
            url = firstFavorite
        } else {
            manager.selectedTabIndex = -1
            url = nil
        }
        if let url {
            manager.selectOrAddWebView(urlString: url)
            variables.searchInSidebar = unformatURL(url: url)
        } else {
            manager.selectedWebView = nil
            variables.searchInSidebar = ""
        }
        UserDefaults.standard.set(selectedSpaceIndex, forKey: "savedSelectedSpaceIndex")
    }

    private func submitCommand(_ input: String, inNewTab: Bool) {
        let query = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        defer {
            variables.tabBarShown = false
            variables.commandBarShown = false
            variables.tapSidebarShown = false
            variables.newTabSearch = ""
        }
        if variables.isBrowseForMe {
            variables.browseForMeSearch = query
            return
        }
        if let url = URL(string: query), url.scheme == "aura" {
            switch url.host {
            case "settings": variables.showSettings = true
            case "history", "dashboard":
                manager.selectedWebView = nil
                variables.auraTab = url.host ?? "dashboard"
            default: break
            }
            return
        }
        guard !spaces.isEmpty else { return }
        let spaceIndex = min(max(selectedSpaceIndex, 0), spaces.count - 1)
        let url = formatURL(from: query)
        variables.auraTab = ""
        if inNewTab || manager.selectedWebView == nil {
            spaces[spaceIndex].tabUrls.append(url)
            manager.selectedTabLocation = .tabs
            manager.selectedTabIndex = spaces[spaceIndex].tabUrls.count - 1
            manager.selectOrAddWebView(urlString: url)
            saveSpaceData()
        } else {
            manager.selectedWebView?.navigate(to: url)
        }
        variables.searchInSidebar = unformatURL(url: url)
        manager.fetchTitlesIfNeeded(for: [url])
        if settings.historyEnabled {
            variables.history.addItem(HistoryItem(title: manager.linksWithTitles[url], websiteURL: url, date: .now))
        }
    }

    func saveSpaceData() {
        Task {
            do {
                try await modelContext.save()
                print("modelContext Saved")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    func validateHTMLResult(thing: String) {
        if removeHeadContent(from: thing) == "<html><body></body></html>" {
            if htmlInspectTimeoutCounter <= 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                    htmlInspectTimeoutCounter += 1
                    validateHTMLResult(thing: thing)
                })
            }
        }
        else {
            inspectCodeString = removeHeadContent(from: thing)
        }
    }
    
    private func navigationButton(imageName: String, action: @escaping () -> Void) -> some View {
        ZStack {
            Circle()
                .fill(variables.navigationArrowColor ? Color(.systemBlue) : Color.gray)
                .shadow(color: Color(.systemBlue), radius: variables.navigationArrowColor ? 10 : 0, x: 0, y: 0)
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .padding(12)
                .scaleEffect(variables.navigationArrowColor ? 1.0 : 0.7)
                .foregroundStyle(Color.white)
            
        }.frame(width: 50, height: 50)
            .gesture(TapGesture().onEnded(action))
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        let newOffset = value.translation.width
        if abs(newOffset) <= 150 {
            variables.navigationOffset = newOffset
        } else {
            variables.navigationOffset = newOffset > 0 ? 150 : -150
        }
        if abs(newOffset) > 100 {
            withAnimation(.linear(duration: 0.3)) {
                variables.navigationArrowColor = true
            }
        } else {
            withAnimation(.linear(duration: 0.3)) {
                variables.navigationArrowColor = false
            }
        }
    }
    
    private func handleDragEnd() {
        if variables.navigationOffset >= 100 {
            goBack()
        } else if variables.navigationOffset < -100 {
            goForward()
        }
        
        withAnimation(.linear(duration: 0.25)) {
            variables.navigationOffset = 0
            variables.navigationArrowColor = false
        }
    }
    
    private func goBack() {
        manager.selectedWebView?.webView.goBack()
    }
    
    private func goForward() {
        manager.selectedWebView?.webView.goForward()
    }
    
    func favoriteRemoveTab(at index: Int) {
        guard manager.selectedSpaceIndex >= 0 && manager.selectedSpaceIndex < spaces.count else { return }
        var temporaryUrls = spaces[manager.selectedSpaceIndex].favoritesUrls
        guard index >= 0 && index < temporaryUrls.count else { return }

        let wasSelected = index == manager.selectedTabIndex && manager.selectedTabLocation == .favorites

        temporaryUrls.remove(at: index)
        spaces[manager.selectedSpaceIndex].favoritesUrls = temporaryUrls

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
        guard manager.selectedSpaceIndex >= 0 && manager.selectedSpaceIndex < spaces.count else { return }
        var temporaryUrls = spaces[manager.selectedSpaceIndex].pinnedUrls
        guard index >= 0 && index < temporaryUrls.count else { return }

        let wasSelected = index == manager.selectedTabIndex && manager.selectedTabLocation == .pinned

        temporaryUrls.remove(at: index)
        spaces[manager.selectedSpaceIndex].pinnedUrls = temporaryUrls

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
        guard manager.selectedSpaceIndex >= 0 && manager.selectedSpaceIndex < spaces.count else { return }
        var temporaryUrls = spaces[manager.selectedSpaceIndex].tabUrls
        guard index >= 0 && index < temporaryUrls.count else { return }

        let wasSelected = index == manager.selectedTabIndex && manager.selectedTabLocation == .tabs

        temporaryUrls.remove(at: index)
        spaces[manager.selectedSpaceIndex].tabUrls = temporaryUrls

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
