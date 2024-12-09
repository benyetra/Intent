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
            JournalEntryView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.bar")
                }
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
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
