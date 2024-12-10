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
    @State private var alertMessage: AlertMessage? // Add this property

    var body: some View {
        NavigationView {
            ZStack {
                Color("LightBackgroundColor").ignoresSafeArea()

                VStack {
                    CustomCalendarView(
                        selectedDate: $selectedDate,
                        datesWithEntries: datesWithEntries,
                        onDateSelected: fetchEntriesForSelectedDate
                    )
                    .padding()
                    .background(Color("SecondaryBackgroundColor"))
                    .cornerRadius(10)
                    .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)

                    Divider()

                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if journalEntries.isEmpty {
                        emptyState
                    } else {
                        entriesList
                    }
                }
                .padding()
                .navigationTitle("Calendar")
                .alert(item: $alertMessage) { alert in
                    Alert(
                        title: Text("Error"),
                        message: Text(alert.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .onAppear {
                    fetchDatesWithEntries()
                    fetchEntriesForSelectedDate(date: selectedDate) // Automatically fetch entries for today
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
                        .frame(width: 65, alignment: .leading) // Slightly increased width
                    }

                    // Entry Details
                    VStack(alignment: .leading, spacing: 4) {
                        // Journal Text
                        Text(entry["text"] as? String ?? "No text")
                            .font(.headline)
                            .foregroundColor(Color("AccentColor"))
                            .lineLimit(2)
                            .truncationMode(.tail)

                        // Goal and Relationship
                        HStack {
                            if let goalTag = entry["goalTag"] as? String {
                                Text("Goal:")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("SecondaryTextColor")) +
                                Text(" \(goalTag)")
                                    .font(.subheadline)
                                    .foregroundColor(Color("SecondaryTextColor"))
                            }

                            if let relationshipTag = entry["relatedPeopleOrLocation"] as? String {
                                Text("Relationship:")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("SecondaryTextColor")) +
                                Text(" \(relationshipTag)")
                                    .font(.subheadline)
                                    .foregroundColor(Color("SecondaryTextColor"))
                            }
                        }
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
                            print("Fetched entryDate: \(entryDate)") // Debug: Check individual dates
                            return entryDate.startOfDay
                        }
                        return nil
                    }.removingDuplicates()
                    print("Dates with entries: \(self.datesWithEntries)")
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
