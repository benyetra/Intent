//
//  IntentsifyApp.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

@main
struct IntentsifyApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showSplash = true // State to manage splash screen visibility

    var body: some Scene {
        WindowGroup {
            if showSplash {
                // Show the splash screen first
                SplashScreenView()
                    .onAppear {
                        // Simulate splash duration
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                // Check login state
                if isLoggedIn {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
        }
    }
}
