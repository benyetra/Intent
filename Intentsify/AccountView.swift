import SwiftUI
import UserNotifications
import CloudKit


struct AccountView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userFullName") private var userFullName: String = "Loading..."
    @AppStorage("userEmail") private var userEmail: String = "Loading..."
    @AppStorage("userRecordID") private var userRecordID: String = ""

    @State private var goals: [String] = []
    @State private var newGoal: String = "" // New goal input
    @State private var isLoadingGoals = false
    @State private var showDeleteConfirmation = false
    @State private var goalToDelete: String?

    var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    // User Info Section
                    userInfoSection

                    // Goals List Section
                    goalsSection

                    // Add New Goal Section
                    addGoalSection

                    Spacer()

                    // Log Out Button
                    logOutButton
                }
                .padding()
                .background(Color("LightBackgroundColor").ignoresSafeArea())
                .onAppear {
                    fetchGoals()
                }
            }
        }

        // MARK: - User Info Section
        private var userInfoSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name: \(userFullName)")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))

                Text("Email: \(userEmail)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("SecondaryBackgroundColor"))
            .cornerRadius(12)
        }

        // MARK: - Goals Section
        private var goalsSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Goals")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))

                if isLoadingGoals {
                    ProgressView("Loading Goals...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if goals.isEmpty {
                    Text("No goals available.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: 8) {
                        ForEach(goals, id: \.self) { goal in
                            HStack {
                                Text(goal)
                                    .font(.body)
                                    .foregroundColor(Color("PrimaryTextColor"))

                                Spacer()

                                Button(action: {
                                    goalToDelete = goal
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("SecondaryBackgroundColor"))
                            )
                        }
                    }
                    .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        // MARK: - Add Goal Section
        private var addGoalSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add New Goal")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryTextColor"))

                HStack {
                    TextField("Enter new goal", text: $newGoal)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("SecondaryBackgroundColor"))
                        )
                        .frame(height: 44)

                    Button(action: addGoal) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .disabled(newGoal.isEmpty)
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color("SecondaryBackgroundColor")))
            }
        }

    // MARK: - Log Out Button
    private var logOutButton: some View {
        Button(action: logOut) {
            Text("Log Out")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity) // Set the button width to the container
                .frame(height: 50)          // Set the button height
                .background(Color.red)
                .cornerRadius(12)
        }
    }

    // MARK: - Fetch and Save Goals
    private func fetchGoals() {
        guard !userRecordID.isEmpty else { return }

        isLoadingGoals = true
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let userRecordID = CKRecord.ID(recordName: self.userRecordID)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)

        let predicate = NSPredicate(format: "userID == %@", userReference)
        let query = CKQuery(recordType: "JournalEntry", predicate: predicate)

        database.perform(query, inZoneWith: nil) { results, error in
            DispatchQueue.main.async {
                isLoadingGoals = false
                if let records = results {
                    self.goals = Array(Set(records.compactMap { $0["goalTag"] as? String }))
                }
            }
        }
    }

    private func addGoal() {
        guard !newGoal.isEmpty else { return }
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let userRecordID = CKRecord.ID(recordName: self.userRecordID)

        let newRecord = CKRecord(recordType: "JournalEntry")
        newRecord["goalTag"] = newGoal
        newRecord["userID"] = CKRecord.Reference(recordID: userRecordID, action: .none)

        database.save(newRecord) { _, error in
            DispatchQueue.main.async {
                if error == nil {
                    goals.append(newGoal)
                    goals = Array(Set(goals)).sorted() // Remove duplicates
                    newGoal = ""
                }
            }
        }
    }

    private func deleteGoal(_ goal: String) {
        guard !userRecordID.isEmpty else { return }
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase

        let userRecordID = CKRecord.ID(recordName: self.userRecordID)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)

        let predicate = NSPredicate(format: "goalTag == %@ AND userID == %@", goal, userReference)
        let query = CKQuery(recordType: "JournalEntry", predicate: predicate)

        database.perform(query, inZoneWith: nil) { results, _ in
            if let records = results {
                for record in records {
                    database.delete(withRecordID: record.recordID) { _, _ in }
                }
                DispatchQueue.main.async {
                    goals.removeAll { $0 == goal }
                }
            }
        }
    }

    // MARK: - Log Out
    private func logOut() {
        isLoggedIn = false
    }
}
