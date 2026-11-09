//
//  NetworkMonitor.swift
//  Aura
//
//  Created by Reyna Myers on 10/7/24.
//

import SwiftUI
import Network

@Observable
class NetworkMonitor {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    var isConnected = true

    init() {
        networkMonitor.pathUpdateHandler = { path in
            let connected = path.status == .satisfied
            DispatchQueue.main.async {
                self.isConnected = connected
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}
