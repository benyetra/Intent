//
//  ContentView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 11/25/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("appleUserIdentifier") private var appleUserIdentifier: String?
    
    var body: some View {
        TabView {
            JournalEntryView(appleUserIdentifier: appleUserIdentifier)
                .tabItem {
                    Label("Journal", systemImage: "book")
                }

            EventLogView()
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }

            TrendsDashboardView()
                .tabItem {
                    Label("Trends", systemImage: "chart.bar")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
