//
//  TrendsView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI
import CloudKit

struct TrendsDashboardView: View {
    @AppStorage("userRecordID") private var userRecordID: String = ""
    @State private var goalStreaks: [String: Int] = [:]
    @State private var relationshipTrends: [String: Int] = [:]
    @State private var goalTrends: [String: Int] = [:]
    @State private var isLoading: Bool = true
    @State private var alertMessage: AlertMessage?

    private var longestStreak: Int {
        goalStreaks.values.max() ?? 1
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("LightBackgroundColor").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Streak Progress
                        StreakProgressView(streaks: goalStreaks, longestStreak: longestStreak)
                            .background(Color("SecondaryBackgroundColor"))
                            .cornerRadius(10)
                            .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)

                        // Trends Charts
                        TrendsChartSection(
                            title: "Goal Trends",
                            data: goalTrends,
                            onClick: { goal in
                                print("Tapped on goal: \(goal)")
                            }
                        )
                        .background(Color("SecondaryBackgroundColor"))
                        .cornerRadius(10)
                        .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    .padding()
                }
                .navigationTitle("Trends")
            }
            .onAppear {
                fetchTrendsData()
            }
            .alert(item: $alertMessage) { alert in
                Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchTrendsData() {
        guard !userRecordID.isEmpty else {
            alertMessage = AlertMessage(message: "User not logged in.")
            return
        }

        isLoading = true
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let predicate = NSPredicate(format: "userID == %@", CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordID), action: .none))
        let query = CKQuery(recordType: "JournalEntry", predicate: predicate)

        database.perform(query, inZoneWith: nil) { results, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.alertMessage = AlertMessage(message: "Failed to fetch trends: \(error.localizedDescription)")
                } else if let records = results {
                    self.processRecords(records)
                }
            }
        }
    }

    private func processRecords(_ records: [CKRecord]) {
        // Reset data
        var streaks: [String: [Date]] = [:]
        var goalCounts: [String: Int] = [:]
        var relationshipCounts: [String: Int] = [:]

        for record in records {
            let goalTag = record["goalTag"] as? String ?? "None"
            let entryDate = (record["entryDate"] as? Date)?.startOfDay
            let relatedPeople = record["relatedPeopleOrLocation"] as? String ?? "None"

            // Build streaks data
            if let entryDate = entryDate {
                if streaks[goalTag] == nil {
                    streaks[goalTag] = []
                }
                streaks[goalTag]?.append(entryDate)
            }

            // Build goal counts
            goalCounts[goalTag, default: 0] += 1

            // Build relationship counts
            let relationships = relatedPeople.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            for relationship in relationships {
                relationshipCounts[relationship, default: 0] += 1
            }
        }

        // Calculate goal streaks
        var calculatedStreaks: [String: Int] = [:]
        for (goal, dates) in streaks {
            let sortedDates = dates.sorted()
            var streak = 1
            for i in 1..<sortedDates.count {
                if Calendar.current.isDate(sortedDates[i - 1], equalTo: sortedDates[i], toGranularity: .day) {
                    continue
                } else if Calendar.current.isDate(sortedDates[i - 1].addingTimeInterval(86400), equalTo: sortedDates[i], toGranularity: .day) {
                    streak += 1
                } else {
                    streak = 1 // Reset streak
                }
            }
            calculatedStreaks[goal] = streak
        }

        // Update UI
        self.goalStreaks = calculatedStreaks
        self.goalTrends = goalCounts
        self.relationshipTrends = relationshipCounts
    }
}

struct StreaksSection: View {
    var goalStreaks: [String: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Goal Streaks")
                .font(.headline)

            ForEach(goalStreaks.sorted(by: { $0.value > $1.value }), id: \.key) { goal, streak in
                HStack {
                    Text(goal)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(streak) days")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
                .padding(.horizontal)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct StreakProgressView: View {
    var streaks: [String: Int]
    var longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Goal Streaks")
                .font(.headline)

            ForEach(streaks.sorted(by: { $0.value > $1.value }), id: \.key) { goal, streak in
                HStack {
                    Text(goal)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(streak) days")
                        .foregroundColor(.secondary)
                }

                // Progress bar visualization
                ProgressView(value: Double(streak), total: Double(longestStreak))
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            }
        }
        .padding()
    }
}



