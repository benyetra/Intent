//
//  CalendarView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI
import CloudKit

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct CalendarView: View {
    @AppStorage("userRecordID") private var userRecordID: String = ""
    @State private var selectedDate: Date = Date()
    @State private var journalEntries: [CKRecord] = []
    @State private var datesWithEntries: [Date] = []
    @State private var isLoading = true
    @State private var alertMessage: AlertMessage?

    var body: some View {
        NavigationView {
            VStack {
                // Custom Calendar
                CustomCalendarView(
                    selectedDate: $selectedDate,
                    datesWithEntries: datesWithEntries,
                    onDateSelected: fetchEntriesForSelectedDate
                )
                .padding()

                Divider()

                if isLoading {
                    ProgressView("Loading...")
                } else if journalEntries.isEmpty {
                    Text("No journal entries for this day.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // List of entries
                    List {
                        ForEach(journalEntries, id: \.recordID) { entry in
                            VStack(alignment: .leading) {
                                Text(entry["text"] as? String ?? "No text")
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(entry["goalTag"] as? String ?? "No goal tag")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(entry["relatedPeopleOrLocation"] as? String ?? "No details")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteEntry)
                    }
                }
            }
            .navigationTitle("Calendar")
            .onAppear {
                fetchDatesWithEntries()
                fetchEntriesForSelectedDate(date: selectedDate)
            }
            .alert(item: $alertMessage) { alert in
                Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
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
