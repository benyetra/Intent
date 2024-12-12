//
//  MainTabView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "AccentColor")
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "ButtonTextColor")
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "ButtonTextColor")!]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                JournalEntryView()
                    .tabItem {
                        Label("Journal", systemImage: "book")
                    }
                    .tag(0)

                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(1)

                TrendsDashboardView()
                    .tabItem {
                        Label("Trends", systemImage: "chart.bar")
                    }
                    .tag(2)

                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "person")
                    }
                    .tag(3)
            }
            .navigationBarTitle(tabTitle(), displayMode: .inline)
        }
    }

    private func tabTitle() -> String {
        switch selectedTab {
        case 0: return "Journal"
        case 1: return "Calendar"
        case 2: return "Trends"
        case 3: return "Account"
        default: return ""
        }
    }
}
