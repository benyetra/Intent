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
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showCheckmark: Bool = false // To control the checkmark animation

    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    Color("LightBackgroundColor").ignoresSafeArea()

                    VStack(spacing: 16) {
                        journalSection
                        datePickerSection
                        goalTagSection
                        relatedPeopleSection
                        saveButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .navigationTitle("Journal Entry")
                    .navigationBarTitleDisplayMode(.inline)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Error"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }

            // Check Mark Animation Overlay
            if showCheckmark {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("AccentColor"))
                        .scaleEffect(1.2)
                        .transition(.scale.combined(with: .opacity))
                }
                .background(
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            self.showCheckmark = false
                        }
                    }
                }
            }
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journal Entry")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))

            TextEditor(text: $journalText)
                .frame(height: 80)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("SecondaryBackgroundColor"))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(journalText.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 2)
                )
                .scrollContentBackground(.hidden) // Hides default `TextEditor` background
        }
    }

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date and Time")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))

            DatePicker("Select Date and Time", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("SecondaryBackgroundColor"))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("AccentColor"), lineWidth: 1)
                )
        }
    }

    private var goalTagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tag a Goal")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))

            TextField("Add a goal tag (e.g., 'Fitness', 'Career')", text: $goalTag)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("SecondaryBackgroundColor"))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(goalTag.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 1)
                )
        }
    }

    private var relatedPeopleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Related People or Location")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))

            TextField("Add names of people or location", text: $relatedPeopleOrLocation)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("SecondaryBackgroundColor"))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(relatedPeopleOrLocation.isEmpty ? Color("ErrorColor") : Color("AccentColor"), lineWidth: 1)
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
            .cornerRadius(8)
        }
        .disabled(isSaving)
        .opacity(isSaving ? 0.6 : 1)
    }

    // Save Journal Entry to CloudKit
    private func saveJournalEntry() {
        guard !userRecordID.isEmpty else {
            showAlert(message: "User is not logged in.")
            return
        }
        
        guard !journalText.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please enter journal text.")
            return
        }
        
        guard !goalTag.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please add a goal tag.")
            return
        }
        
        guard !relatedPeopleOrLocation.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please add related people or location.")
            return
        }
        
        isSaving = true
        
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
                    self.showAlert(message: "Failed to save: \(error.localizedDescription)")
                } else {
                    self.clearForm()
                    withAnimation {
                        self.showCheckmark = true
                    }
                }
            }
        }
    }

    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
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

