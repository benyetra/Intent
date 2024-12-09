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

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

