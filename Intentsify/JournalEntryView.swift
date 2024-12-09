//
//  JournalEntryView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI
import CloudKit

struct JournalEntryView: View {
    @AppStorage("userRecordID") private var userRecordID: String = ""
    @State private var journalText: String = ""
    @State private var entryDate: Date = Date()
    @State private var goalTag: String = ""
    @State private var relatedPeopleOrLocation: String = ""
    @State private var isSaving: Bool = false
    @State private var saveError: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Journal Text Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Journal Entry")
                            .font(.headline)
                        
                        TextEditor(text: $journalText)
                            .frame(minHeight: 150, maxHeight: .infinity) // Set flexible height
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                            .scrollContentBackground(.hidden)
                    }
                    
                    // Date and Time Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date and Time")
                            .font(.headline)
                        
                        DatePicker("Select Date and Time", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                    }
                    
                    // Goal Tag Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag a Goal")
                            .font(.headline)
                        
                        TextField("Add a goal tag (e.g., 'Fitness', 'Career')", text: $goalTag)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                    }
                    
                    // Related People or Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related People or Location")
                            .font(.headline)
                        
                        TextField("Add names of people or location", text: $relatedPeopleOrLocation)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                    }
                    
                    // Save Button
                    Button(action: saveJournalEntry) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Save Entry")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isSaving)
                    
                    // Error Message
                    if let saveError = saveError {
                        Text(saveError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top)
                    }
                }
                .padding()
            }
            .navigationTitle("New Journal Entry")
        }
    }
    
    // Save Journal Entry to CloudKit
    private func saveJournalEntry() {
        guard !userRecordID.isEmpty else {
            saveError = "User is not logged in."
            return
        }
        
        guard !journalText.trimmingCharacters(in: .whitespaces).isEmpty else {
            saveError = "Please enter journal text."
            return
        }

        isSaving = true
        saveError = nil

        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let record = CKRecord(recordType: "JournalEntry")
        
        // Associate the entry with the user
        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordID), action: .none)
        record["userID"] = userReference
        record["text"] = journalText
        record["entryDate"] = entryDate as NSDate
        record["goalTag"] = goalTag.isEmpty ? "None" : goalTag
        record["relatedPeopleOrLocation"] = relatedPeopleOrLocation.isEmpty ? "None" : relatedPeopleOrLocation

        // Save to CloudKit
        database.save(record) { _, error in
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    self.saveError = "Failed to save: \(error.localizedDescription)"
                } else {
                    self.clearForm()
                }
            }
        }
    }
    
    // Clear Form After Saving
    private func clearForm() {
        journalText = ""
        entryDate = Date()
        goalTag = ""
        relatedPeopleOrLocation = ""
    }
}

#Preview {
    JournalEntryView()
}
