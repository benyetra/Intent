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
    @State private var goalAchieved: String = "" // Track thumbs-up or thumbs-down
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
                        datePickerSection
                        journalSection
                        goalTagSection
                        relatedPeopleSection
                        goalAchievedSection
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
            .navigationViewStyle(StackNavigationViewStyle())

            // Checkmark Animation Overlay
            if showCheckmark {
                ZStack {
                    // Background blur and dim effect
                    Color.gray.opacity(0.4)
                        .ignoresSafeArea()
                        .blur(radius: 5)

                    // Checkmark animation
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(Color("AccentColor"))
                            .scaleEffect(showCheckmark ? 1 : 0.5)
                            .opacity(showCheckmark ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3), value: showCheckmark)

                        Text("Entry Saved!")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryTextColor"))
                            .padding(.top, 8)
                    }
                }
                .transition(.opacity)
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
            Text("Event Description")
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
                .labelsHidden() // Hides the label for a cleaner look
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure left alignment
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
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure the whole section is left-aligned
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

    private var goalAchievedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Did you progress this goal?")
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))

            HStack(spacing: 16) {
                Button(action: {
                    goalAchieved = "true"
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Yes")
                    }
                    .foregroundColor(goalAchieved == "true" ? .green : .gray)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(goalAchieved == "true" ? Color.green.opacity(0.2) : Color.clear)
                    )
                }

                Button(action: {
                    goalAchieved = "false"
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsdown.fill")
                        Text("No")
                    }
                    .foregroundColor(goalAchieved == "false" ? .red : .gray)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(goalAchieved == "false" ? Color.red.opacity(0.2) : Color.clear)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Aligns the HStack to the left
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
        
        guard !goalAchieved.isEmpty else { // Direct check for empty string
            showAlert(message: "Please indicate whether the goal was achieved.")
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
        record["goalAchieved"] = goalAchieved // Save directly as a String
        
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
        goalAchieved = ""
    }
}
