//
//  MainTabView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                JournalEntryView()
            }
            .navigationViewStyle(StackNavigationViewStyle()) // Force single column
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
    }
}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}


#Preview {
    MainTabView()
}
