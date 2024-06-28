//
//  InternetMonitor.swift
//  Mod9 Practica1
//
//  Created by MAGH on 08/06/24.
//

import Foundation
import Network

class InternetMonitor: ObservableObject {
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "Monitor")
    var isConnected = false
    var connType = ""
    
    init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            if path.usesInterfaceType(.wifi) {
                self.connType = "Wi-Fi"
            } else if  path.usesInterfaceType(.cellular) {
                self.connType = "Cellular"
            } else if  path.usesInterfaceType(.wiredEthernet) {
                self.connType = "Ethernet"
            } else {
                self.connType = "Other"
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
}
