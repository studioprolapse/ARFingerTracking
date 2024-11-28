//
//  AppDelegate.swift
//  testing-hand
//
//  Created by kotars01 on 13/06/2023.
//

import SwiftUI

@main
struct ARFingerTrackApp: App {
  @StateObject var sessionHandler : SessionHandler = SessionHandler()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(sessionHandler)
    }
  }
}
