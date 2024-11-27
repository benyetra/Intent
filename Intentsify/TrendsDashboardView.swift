import SwiftUI
import Charts

struct TrendsDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: true)],
        animation: .default
    ) private var journalEntries: FetchedResults<JournalEntry>

    @State private var longestStreakGoal: String = ""
    @State private var longestStreak: Int = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Goal Streaks Section
                    Section(header: Text("Goal Streaks").font(.headline)) {
                        goalStreakProgressRings()
                    }
                    .padding(.bottom, 20)

                    // Trends Section
                    Section(header: Text("Relationship & Goal Trends").font(.headline)) {
                        relationshipAndGoalTrends()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Trends")
            .onAppear {
                updateLongestStreak()
            }
        }
    }

    // MARK: - Goal Streaks Progress Rings
    private func goalStreakProgressRings() -> some View {
        let streaks = calculateGoalStreaks()

        return VStack {
            // Motivational Text
            if longestStreak > 0 {
                Text("🏅 You're crushing it with \(longestStreak) days on \(longestStreakGoal)! Keep the streak alive!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(streaks) { streak in
                        VStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .trim(from: 0, to: min(CGFloat(streak.streak) / 30, 1))
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.green]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 120, height: 120)
                                    .animation(.easeInOut(duration: 1.0), value: streak.streak)

                                Text("\(streak.streak)")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                            Text(streak.goal)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Relationship & Goal Trends
    private func relationshipAndGoalTrends() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Relationship Insights Section
            VStack(alignment: .leading) {
                Text("Relationship Insights")
                    .font(.headline)
                    .padding(.bottom, 10)

                let relationshipCounts = calculateRelationshipCounts()

                if relationshipCounts.isEmpty {
                    Text("No data available for relationships yet.")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(relationshipCounts) { data in
                                VStack {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                                            .frame(width: 80, height: 80)

                                        Circle()
                                            .trim(from: 0, to: CGFloat(data.count) / 10)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 80, height: 80)
                                            .animation(.easeInOut(duration: 1.0), value: data.count)

                                        Text("\(data.count)")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(.orange)
                                    }
                                    Text(data.relationship)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity) // Ensure it doesn't get truncated
            .background(Color(.systemBackground)) // Add background for clarity
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            Divider()

            // Goal Progress Trends Section
            VStack(alignment: .leading) {
                Text("Goal Progress Trends")
                    .font(.headline)
                    .padding(.bottom, 10)

                let goalProgressCounts = calculateGoalProgressCounts()

                if goalProgressCounts.isEmpty {
                    Text("No data available for goals yet.")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Chart {
                        ForEach(goalProgressCounts) { progress in
                            BarMark(
                                x: .value("Goal", progress.goal),
                                y: .value("Count", progress.count)
                            )
                            .foregroundStyle(by: .value("Type", progress.type))
                        }
                    }
                    .frame(height: 300)
                    .chartXAxis {
                        AxisMarks { _ in AxisGridLine() }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartLegend(.visible)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity) // Adjust to prevent cutoff
    }

    // MARK: - Data Calculations
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
                    streaksByGoal[goal] = (streak: streaksByGoal[goal]!.streak + 1, lastDate: date)
                } else {
                    streaksByGoal[goal] = (streak: 1, lastDate: date)
                }
            }
        }

        return streaksByGoal.compactMap { (goal, data) -> GoalStreak? in
            guard let validDate = data.lastDate else { return nil }
            return GoalStreak(date: validDate, streak: data.streak, goal: goal)
        }.sorted { $0.date < $1.date }
    }

    private func calculateRelationshipCounts() -> [RelationshipData] {
        var counts: [String: Int] = [:]

        for entry in journalEntries {
            if let relationship = entry.relationship, !relationship.isEmpty {
                counts[relationship, default: 0] += 1
            }
        }

        return counts.map { RelationshipData(relationship: $0.key, count: $0.value) }
    }

    private func calculateGoalProgressCounts() -> [GoalProgressData] {
        var counts: [String: (positive: Int, negative: Int)] = [:]

        for entry in journalEntries {
            if let tags = entry.tags, let content = entry.content {
                let goals = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let isPositive = content.contains("good") || content.contains("success")
                let isNegative = content.contains("bad") || content.contains("fail")

                for goal in goals {
                    if isPositive {
                        counts[goal, default: (0, 0)].positive += 1
                    } else if isNegative {
                        counts[goal, default: (0, 0)].negative += 1
                    }
                }
            }
        }

        return counts.flatMap { goal, progress -> [GoalProgressData] in
            [
                GoalProgressData(goal: goal, count: progress.positive, type: "Positive"),
                GoalProgressData(goal: goal, count: progress.negative, type: "Negative")
            ]
        }
    }

    private func updateLongestStreak() {
        let streaks = calculateGoalStreaks()
        if let longest = streaks.max(by: { $0.streak < $1.streak }) {
            longestStreakGoal = longest.goal
            longestStreak = longest.streak
        }
    }
}

// MARK: - Supporting Models
struct GoalStreak: Identifiable {
    let id = UUID()
    let date: Date
    let streak: Int
    let goal: String
}

struct RelationshipData: Identifiable {
    let id = UUID()
    let relationship: String
    let count: Int
}

struct GoalProgressData: Identifiable {
    let id = UUID()
    let goal: String
    let count: Int
    let type: String
}

extension String {
    func capitalizeWords() -> String {
        self.lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

