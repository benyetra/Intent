//
//  CalendarView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI
import CloudKit

struct CalendarView: View {
    @AppStorage("userRecordID") private var userRecordID: String = ""
    @State private var selectedDate: Date = Date()
    @State private var journalEntries: [CKRecord] = []
    @State private var datesWithEntries: [Date] = []
    @State private var isLoading = true
    @State private var alertMessage: AlertMessage?

    var body: some View {
        NavigationView {
            ZStack {
                Color("LightBackgroundColor").ignoresSafeArea()

                VStack(spacing: 16) {
                    // Calendar View
                    CustomCalendarView(
                        selectedDate: $selectedDate,
                        datesWithEntries: datesWithEntries,
                        onDateSelected: fetchEntriesForSelectedDate
                    )
                    .padding([.horizontal, .top], 16) // Raise the calendar
                    .padding(.bottom, 8)
                    .background(Color("SecondaryBackgroundColor"))
                    .cornerRadius(10)
                    .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)

                    Divider()

                    // List or Empty State
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if journalEntries.isEmpty {
                        emptyState
                    } else {
                        entriesList
                    }
                }
                .navigationTitle("Historical Events")
                .alert(item: $alertMessage) { alert in
                    Alert(
                        title: Text("Error"),
                        message: Text(alert.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .onAppear {
                    fetchDatesWithEntries()
                    fetchEntriesForSelectedDate(date: selectedDate) // Fetch entries for today
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var entriesList: some View {
        List {
            ForEach(journalEntries.sorted(by: { ($0["entryDate"] as? Date) ?? Date() < ($1["entryDate"] as? Date) ?? Date() }), id: \.recordID) { entry in
                HStack(alignment: .top, spacing: 12) {
                    // Entry Time
                    if let entryDate = entry["entryDate"] as? Date {
                        VStack {
                            Text(entryDate.formatted(date: .omitted, time: .shortened))
                                .font(.headline)
                                .foregroundColor(Color("AccentColor"))
                        }
                        .frame(width: 65, alignment: .leading)
                    }

                    // Entry Details
                    VStack(alignment: .leading, spacing: 4) {
                        // Main Text
                        Text(entry["text"] as? String ?? "No text")
                            .font(.headline)
                            .foregroundColor(Color("AccentColor"))
                            .lineLimit(2)
                            .truncationMode(.tail)

                        // Goal and Relationship
                        VStack(alignment: .leading, spacing: 2) {
                            if let goalTag = entry["goalTag"] as? String {
                                HStack {
                                    Text("Goal:")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    Text(goalTag)
                                        .font(.subheadline)
                                        .foregroundColor(Color("SecondaryTextColor"))
                                }
                            }

                            if let relationshipTag = entry["relatedPeople"] as? String {
                                HStack {
                                    Text("Relationship:")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    Text(relationshipTag)
                                        .font(.subheadline)
                                        .foregroundColor(Color("SecondaryTextColor"))
                                }
                            }
                        }
                    }

                    Spacer() // Push the thumbs icon to the right

                    // Thumbs-up or Thumbs-down icon
                    if let goalAchieved = entry["goalAchieved"] as? String {
                        Image(systemName: goalAchieved == "true" ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                            .font(.system(size: 18)) // Slightly larger for better visibility
                            .foregroundColor(goalAchieved == "true" ? .green : .red)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color("SecondaryBackgroundColor"))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .padding(.trailing, 8) // Add spacing from the row edge
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color("SecondaryBackgroundColor")) // Set background
            }
            .onDelete(perform: deleteEntry) // Enable swipe-to-delete
        }
        .listStyle(PlainListStyle()) // Use plain style for a cleaner appearance
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No entries for this date.")
                .font(.headline)
                .foregroundColor(Color("SecondaryTextColor"))
            Spacer()
        }
    }

    // Fetch Dates with Entries
    private func fetchDatesWithEntries() {
        guard !userRecordID.isEmpty else { return }

        isLoading = true
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase

        let predicate = NSPredicate(format: "userID == %@", CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordID), action: .none))
        let query = CKQuery(recordType: "JournalEntry", predicate: predicate)

        database.perform(query, inZoneWith: nil) { results, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.alertMessage = AlertMessage(message: "Failed to fetch dates: \(error.localizedDescription)")
                } else if let records = results {
                    self.datesWithEntries = records.compactMap { record in
                        if let entryDate = record["entryDate"] as? Date {
                            return entryDate.startOfDay
                        }
                        return nil
                    }.removingDuplicates()
                } else {
                    self.datesWithEntries = []
                }
            }
        }
    }

    // Fetch Entries for Selected Date
    private func fetchEntriesForSelectedDate(date: Date) {
        guard !userRecordID.isEmpty else { return }

        isLoading = true
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase

        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let predicate = NSPredicate(
            format: "userID == %@ AND entryDate >= %@ AND entryDate < %@",
            CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordID), action: .none),
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        let query = CKQuery(recordType: "JournalEntry", predicate: predicate)

        database.perform(query, inZoneWith: nil) { results, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.alertMessage = AlertMessage(message: "Failed to fetch entries: \(error.localizedDescription)")
                } else {
                    self.journalEntries = results ?? []
                }
            }
        }
    }

    // Delete Entry
    private func deleteEntry(at offsets: IndexSet) {
        guard let index = offsets.first else { return }

        let recordToDelete = journalEntries[index]
        journalEntries.remove(at: index)

        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase

        database.delete(withRecordID: recordToDelete.recordID) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.alertMessage = AlertMessage(message: "Failed to delete entry: \(error.localizedDescription)")
                }
            } else {
                DispatchQueue.main.async {
                    self.fetchDatesWithEntries() // Refresh dots on calendar
                }
            }
        }
    }
}


#Preview {
    CalendarView()
}
