import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    init() {
        // Configure the UITabBar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(named: "AccentColor")
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "ButtonTextColor")
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "ButtonTextColor")!]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Configure the UINavigationBar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(named: "AccentColor")
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(named: "PrimaryTextColor")!,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold) // Optional: Adjust font
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "PrimaryTextColor")!,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold) // Optional: Adjust large font
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
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
            .navigationTitle(tabTitle())
            .navigationBarTitleDisplayMode(.inline) // Inline title
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
