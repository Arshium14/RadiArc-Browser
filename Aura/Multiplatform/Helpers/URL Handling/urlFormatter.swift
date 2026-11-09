//
//  urlFormatter.swift
//  iPad browser
//
//  Created by Reyna Myers on 15/4/24.
//

import SwiftUI

func formatURL(from input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return trimmed }

    // Check if it's already a URL with a scheme
    if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() {
        if scheme == "http" || scheme == "https" || scheme == "aura" || scheme == "about" || scheme == "file" {
            return trimmed
        }
        return "https://\(trimmed)"
    }

    // Check if it's a URL without a scheme
    if let url = URL(string: "https://\(trimmed)"), url.host != nil {
        if trimmed.contains(".") && !trimmed.contains(" ") {
            return url.absoluteString
        }
    }

    // Assume it's a search term and format it for the configured search engine
    let searchEngine = UserDefaults.standard.string(forKey: "searchEngine") ?? "https://www.google.com/search?q="
    let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+#"))
    let searchTerms = trimmed
        .components(separatedBy: " ")
        .map { $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? $0 }
        .joined(separator: "+")
    return "\(searchEngine)\(searchTerms)"
}


func unformatURL(url: String) -> String {
    let searchEngine = UserDefaults.standard.string(forKey: "searchEngine") ?? "https://www.google.com/search?q="
    
    var formattedUrl = url
    if url.starts(with: searchEngine) {
        formattedUrl = formattedUrl.replacingOccurrences(of: searchEngine, with: "")
        //formattedUrl.removeEverythingAfter(str: "&")
        formattedUrl = formattedUrl.components(separatedBy: "&")[0]
        if formattedUrl.last == "/" {
            formattedUrl.removeLast()
        }
        formattedUrl = formattedUrl.replacingOccurrences(of: "+", with: " ")
        formattedUrl = formattedUrl.replacingOccurrences(of: "%20", with: " ")
    }
    else {
        formattedUrl = formattedUrl.replacingOccurrences(of: "https://", with: "")
        formattedUrl = formattedUrl.replacingOccurrences(of: "http://", with: "")
        formattedUrl = formattedUrl.replacingOccurrences(of: "www.", with: "")
        if formattedUrl.last == "/" {
            formattedUrl.removeLast()
        }
    }
    
    
    return formattedUrl
}


func unformatPlainURL(url: String) -> String {
    var formattedUrl = url
    
        formattedUrl = formattedUrl.replacingOccurrences(of: "https://", with: "")
        formattedUrl = formattedUrl.replacingOccurrences(of: "http://", with: "")
        formattedUrl = formattedUrl.replacingOccurrences(of: "www.", with: "")
        if formattedUrl.last == "/" {
            formattedUrl.removeLast()
        }
    
    
    
    return formattedUrl
}
