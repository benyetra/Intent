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
            ZStack {
                // Light background inspired by app icon
                Color("LightBackgroundColor")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Journal Text Section
                        journalSection

                        // Date Picker Section
                        datePickerSection

                        // Goal Tag Section
                        goalTagSection

                        // Related People Section
                        relatedPeopleSection

                        // Save Button Section
                        saveButton

                        // Error Message Section
                        if let saveError = saveError {
                            Text(saveError)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                }
            }
            .navigationTitle("Intentsify")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journal Entry")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)

            TextEditor(text: $journalText)
                .frame(minHeight: 150)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(journalText.isEmpty ? Color.red : Color("AccentColor"), lineWidth: 2)
                )
        }
    }

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date and Time")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)

            DatePicker("Select Date and Time", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("AccentColor"), lineWidth: 2)
                )
        }
    }

    private var goalTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tag a Goal")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)

            TextField("Add a goal tag (e.g., 'Fitness', 'Career')", text: $goalTag)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(goalTag.isEmpty ? Color.red : Color("AccentColor"), lineWidth: 2)
                )
        }
    }

    private var relatedPeopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related People or Location")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)

            TextField("Add names of people or location", text: $relatedPeopleOrLocation)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(relatedPeopleOrLocation.isEmpty ? Color.red : Color("AccentColor"), lineWidth: 2)
                )
        }
    }

    private var saveButton: some View {
        Button(action: saveJournalEntry) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(.white)
                } else {
                    Text("Submit Entry")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("AccentColor"))
            .cornerRadius(10)
        }
        .disabled(isSaving)
        .opacity(isSaving ? 0.6 : 1)
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

        guard !goalTag.trimmingCharacters(in: .whitespaces).isEmpty else {
            saveError = "Please add a goal tag."
            return
        }

        guard !relatedPeopleOrLocation.trimmingCharacters(in: .whitespaces).isEmpty else {
            saveError = "Please add related people or location."
            return
        }

        isSaving = true
        saveError = nil

        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let record = CKRecord(recordType: "JournalEntry")

        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordID), action: .none)
        record["userID"] = userReference
        record["text"] = journalText
        record["entryDate"] = entryDate as NSDate
        record["goalTag"] = goalTag
        record["relatedPeopleOrLocation"] = relatedPeopleOrLocation

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
