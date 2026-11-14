//
//  SettingsVariables.swift
//  Aura
//
//  Created by Reyna Myers on 8/7/24.
//

import SwiftUI
import Combine

class SettingsVariables: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    let shortcuts = KeyboardShortcuts()

    // AppStorage in a reference type does not publish binding changes to its observers.
    @AppStorage("email") var email = "" {
        willSet { objectWillChange.send() }
    }

    @AppStorage("hoverEffectsAbsorbCursor") var hoverEffectsAbsorbCursor = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("favoritesStyle") var favoritesStyle = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("faviconLoadingStyle") var faviconLoadingStyle = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("showBorder") var showBorder = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("disableSidebarHover") var disableSidebarHover = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("sidebarLeft") var sidebarLeft = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("hideSidebar") var hideSidebar = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("searchEngine") var searchEngine = "https://www.google.com/search?q=" {
        willSet { objectWillChange.send() }
    }

    @AppStorage("prefferedColorScheme") var prefferedColorScheme = "automatic" {
        willSet { objectWillChange.send() }
    }

    // Apply at the scene root, not inside individual settings destinations.
    var preferredScheme: ColorScheme? {
        switch prefferedColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    @AppStorage("swipingSpaces") var swipingSpaces = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("onboardingDone") var onboardingDone = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("faviconShape") var faviconShape = "circle" {
        willSet { objectWillChange.send() }
    }

    @AppStorage("forceDarkMode") var forceDarkMode = "none" {
        willSet { objectWillChange.send() }
    }

    @AppStorage("forceDarkModeTime") var forceDarkModeTime = "system" {
        willSet { objectWillChange.send() }
    }

    @AppStorage("commandBarOnLaunch") var commandBarOnLaunch = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("adBlockEnabled") var adBlockEnabled = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("swipeNavigationDisabled") var swipeNavigationDisabled = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("launchAnimation") var launchAnimation = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("reduceMotion") var reduceMotion = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("apiKey") var apiKey = "" {
        willSet { objectWillChange.send() }
    }

    @AppStorage("openAPIKey") var openAPIKey = "" {
        willSet { objectWillChange.send() }
    }

    @AppStorage("preloadingWebsites") var preloadingWebsites = 15.0 {
        willSet { objectWillChange.send() }
    }

    @AppStorage("hideBrowseForMe") var hideBrowseForMe = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("historyEnabled") var historyEnabled = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("hideMagnifyingGlassSearch") var hideMagnifyingGlassSearch = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("pinnedTabCornerRadius") var favoriteTabCornerRadius = 20.0 {
        willSet { objectWillChange.send() }
    }

    @AppStorage("pinnedTabBorderWidth") var favoriteTabBorderWidth = 2.0 {
        willSet { objectWillChange.send() }
    }

    @AppStorage("jsInjectionDelay") var jsInjectionDelay = 3.0 {
        willSet { objectWillChange.send() }
    }

    @AppStorage("jsInjectionDelayBoosts") var jsInjectionDelayBoosts = 3.0 {
        willSet { objectWillChange.send() }
    }

    @AppStorage("horizontalTabBar") var horizontalTabBar = false {
        willSet { objectWillChange.send() }
    }

    @AppStorage("shareButtonInTabBar") var shareButtonInTabBar = true {
        willSet { objectWillChange.send() }
    }

    @AppStorage("gridColumnCount") var gridColumnCount = 2.0 {
        willSet { objectWillChange.send() }
    }

    @AppStorage("userAgent") var userAgent = "Mozilla/5.0 (iPad; CPU OS 18_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/136.0.7103.91 Mobile/15E148 Safari/604.1" {
        willSet { objectWillChange.send() }
    }
}
