import SwiftUI
import CoreData

struct JournalEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: false)],
        animation: .default
    ) private var journalEntries: FetchedResults<JournalEntry>

    @State private var journalText: String = ""
    @State private var goals: String = ""
    @State private var relationship: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showAlert: Bool = false
    @State private var goalSuggestions: [String] = [] // Suggestions and existing goals

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.1)]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        Text("Journal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)

                        // Journal Entry Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Write Your Journal")
                                .font(.headline)

                            TextEditor(text: $journalText)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                .frame(height: 150)
                        }
                        .padding(.horizontal)

                        // Goals Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Goals")
                                .font(.headline)

                            TextField("Add goals (comma-separated)", text: $goals)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                .onChange(of: goals) { _ in
                                    updateGoalSuggestions()
                                }

                            // Display Suggested and Existing Goals
                            if !goalSuggestions.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(goalSuggestions, id: \.self) { goal in
                                            Text(goal.capitalized)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(Color.blue)
                                                .font(.subheadline)
                                                .clipShape(Capsule())
                                                .onTapGesture {
                                                    addGoal(goal)
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Relationship Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Relationship (place/person)")
                                .font(.headline)

                            TextField("Add relationship", text: $relationship)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        .padding(.horizontal)

                        // Date Picker Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Date")
                                .font(.headline)

                            DatePicker("Select date and time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        .padding(.horizontal)

                        // Save Button
                        Button(action: saveJournalEntry) {
                            Text("Save Entry")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)

                        // Divider
                        Divider()

                        // Journal Entries Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Previous Entries")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(journalEntries) { entry in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(entry.date ?? Date(), formatter: DateFormatter.fullDateTime)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    Text(entry.content ?? "")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    if let goals = entry.tags, !goals.isEmpty {
                                        Text("Goals: \(goals.capitalizeWords())")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }

                                    if let relationship = entry.relationship, !relationship.isEmpty {
                                        Text("Relationship: \(relationship.capitalizeWords())")
                                            .font(.footnote)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                fetchGoalSuggestions()
            }
        }
    }

    // MARK: - Methods

    private func saveJournalEntry() {
        guard !journalText.isEmpty else {
            showAlert = true
            return
        }

        let newEntry = JournalEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.date = selectedDate
        newEntry.content = journalText
        newEntry.tags = goals
        newEntry.relationship = relationship

        do {
            try viewContext.save()
            journalText = ""
            goals = ""
            relationship = ""
            selectedDate = Date()
            fetchGoalSuggestions() // Refresh suggestions
        } catch {
            print("Failed to save journal entry: \(error.localizedDescription)")
        }
    }

    private func fetchGoalSuggestions() {
        var uniqueGoals: Set<String> = []
        for entry in journalEntries {
            if let tags = entry.tags {
                let goalsArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                uniqueGoals.formUnion(goalsArray)
            }
        }
        goalSuggestions = Array(uniqueGoals).sorted()
    }

    private func updateGoalSuggestions() {
        guard !goals.isEmpty else {
            fetchGoalSuggestions()
            return
        }

        let inputGoals = goals.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        if let lastInput = inputGoals.last, !lastInput.isEmpty {
            goalSuggestions = goalSuggestions.filter { $0.hasPrefix(lastInput) }
        } else {
            fetchGoalSuggestions()
        }
    }

    private func addGoal(_ goal: String) {
        let currentGoals = goals.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        if !currentGoals.contains(goal) {
            goals += goals.isEmpty ? goal : ", \(goal)"
        }
        goalSuggestions = [] // Clear suggestions
    }
}

extension DateFormatter {
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
