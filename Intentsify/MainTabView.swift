//
//  MainTabView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

struct MainTabView: View {
    init() {
        // Configure the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() // Ensure no transparency
        appearance.backgroundColor = UIColor(named: "AccentColor") // Use AccentColor
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "ButtonTextColor")
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "ButtonTextColor")!]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            NavigationView {
                JournalEntryView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Journal", systemImage: "book")
            }

            NavigationView {
                CalendarView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            NavigationView {
                TrendsDashboardView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Trends", systemImage: "chart.bar.xaxis")
            }

            NavigationView {
                AccountView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Account", systemImage: "person.crop.circle")
            }
        }
        .background(Color("LightBackgroundColor")) // Ensure no transparent areas
        .edgesIgnoringSafeArea(.top) // Prevents unwanted gaps at the top of the screen
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
