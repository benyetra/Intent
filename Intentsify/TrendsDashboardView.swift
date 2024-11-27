import SwiftUI
import Charts

struct TrendsDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: true)],
        animation: .default)
    private var journalEntries: FetchedResults<JournalEntry>

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Streaks Section
                    Section(header: Text("Goal Streaks").font(.headline)) {
                        goalStreakChart()
                    }

                    // Trends Section
                    Section(header: Text("Relationship & Goal Trends").font(.headline)) {
                        relationshipAndGoalTrendsChart()
                    }
                }
                .padding()
            }
            .navigationTitle("Trends")
        }
    }

    // MARK: - Goal Streaks Chart
    private func goalStreakChart() -> some View {
        let streaks = calculateGoalStreaks()

        return Chart {
            ForEach(streaks) { streak in
                LineMark(
                    x: .value("Day", streak.date, unit: .day),
                    y: .value("Streak", streak.streak)
                )
                .foregroundStyle(by: .value("Goal", streak.goal))

                PointMark(
                    x: .value("Day", streak.date, unit: .day),
                    y: .value("Streak", streak.streak)
                )
                .annotation(position: .top) {
                    Text(streak.goal)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(height: 300)
    }

    // MARK: - Relationship & Goal Trends Chart
    private func relationshipAndGoalTrendsChart() -> some View {
        let trends = calculateRelationshipAndGoalTrends()

        return Chart(trends) {
            BarMark(
                x: .value("Category", $0.category),
                y: .value("Count", $0.count)
            )
            .foregroundStyle(by: .value("Type", $0.type))
        }
        .frame(height: 300)
    }

    // MARK: - Data Calculations

    // Goal Streak Calculation
    private func calculateGoalStreaks() -> [GoalStreak] {
        let calendar = Calendar.current
        var streaksByGoal: [String: (streak: Int, lastDate: Date?)] = [:]

        for entry in journalEntries {
            guard let date = entry.date, let tags = entry.tags else { continue }

            let goals = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).capitalizeWords() }

            for goal in goals {
                if let lastDate = streaksByGoal[goal]?.lastDate,
                   let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate),
                   calendar.isDate(date, inSameDayAs: nextDate) {
                    // Continue the streak
                    streaksByGoal[goal] = (streak: streaksByGoal[goal]!.streak + 1, lastDate: date)
                } else {
                    // Start a new streak
                    streaksByGoal[goal] = (streak: 1, lastDate: date)
                }
            }
        }

        // Convert to GoalStreak array for the chart
        return streaksByGoal.compactMap { (goal, data) -> GoalStreak? in
            guard let validDate = data.lastDate else { return nil } // Skip invalid dates
            return GoalStreak(date: validDate, streak: data.streak, goal: goal)
        }.sorted { $0.date < $1.date }
    }

    // Relationship and Goal Trends Calculation
    private func calculateRelationshipAndGoalTrends() -> [TrendData] {
        var trends: [TrendData] = []
        var positiveCounts: [String: Int] = [:]
        var negativeCounts: [String: Int] = [:]

        for entry in journalEntries {
            guard let content = entry.content else { continue }

            // Analyze positivity or negativity
            let isPositive = content.contains("good") || content.contains("success")
            let isNegative = content.contains("bad") || content.contains("fail")

            // Count relationships
            if let relationship = entry.relationship, !relationship.isEmpty {
                if isPositive {
                    positiveCounts[relationship, default: 0] += 1
                } else if isNegative {
                    negativeCounts[relationship, default: 0] += 1
                }
            }

            // Count goals (tags)
            if let tags = entry.tags {
                let goals = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                for goal in goals {
                    if isPositive {
                        positiveCounts[goal, default: 0] += 1
                    } else if isNegative {
                        negativeCounts[goal, default: 0] += 1
                    }
                }
            }
        }

        // Convert counts to TrendData
        for (category, count) in positiveCounts {
            trends.append(TrendData(category: category, count: count, type: "Positive"))
        }
        for (category, count) in negativeCounts {
            trends.append(TrendData(category: category, count: count, type: "Negative"))
        }

        return trends
    }
}

extension String {
    func capitalizeWords() -> String {
        self.lowercased()
            .split(separator: " ") // Split string into words
            .map { $0.prefix(1).uppercased() + $0.dropFirst() } // Capitalize each word
            .joined(separator: " ") // Rejoin words with spaces
    }
}

// MARK: - Supporting Models

struct GoalStreak: Identifiable {
    let id = UUID()
    let date: Date
    let streak: Int
    let goal: String
}

struct TrendData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let type: String
}
