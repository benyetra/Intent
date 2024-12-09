//
//  AccountsView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI
import UserNotifications
import CloudKit

struct AccountView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userFullName") private var userFullName: String = "Loading..."
    @AppStorage("userEmail") private var userEmail: String = "Loading..."
    @AppStorage("userRecordID") private var userRecordID: String = ""

    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var showNotificationPermissionAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color("LightBackgroundColor").ignoresSafeArea() // App background color
                
                VStack(spacing: 30) {
                    // User Info Section
                    infoSection

                    // Daily Journal Reminder
                    reminderSection

                    Spacer()

                    // Log Out Button
                    logoutButton
                }
                .padding()
                .navigationTitle("Account")
                .onAppear {
                    checkNotificationPermission()
                    fetchReminderTimeFromCloudKit()
                }
                .alert("Notification Permission Required", isPresented: $showNotificationPermissionAlert) {
                    Button("Go to Settings") {
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(appSettings)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Please enable notifications in Settings to receive daily journal reminders.")
                }
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Full Name: \(userFullName)")
                .font(.headline)
                .foregroundColor(.primary)
            Text("Email: \(userEmail)")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryTextColor"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color("SecondaryBackgroundColor"))
        .cornerRadius(12)
        .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Journal Reminder")
                .font(.headline)
                .foregroundColor(.primary)
            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .onChange(of: reminderTime) { newTime in
                    scheduleNotification(for: newTime)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color("SecondaryBackgroundColor"))
        .cornerRadius(12)
        .shadow(color: Color("AccentColor").opacity(0.2), radius: 5, x: 0, y: 2)
    }

    private var logoutButton: some View {
        Button(action: { isLoggedIn = false }) {
            Text("Log Out")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(12)
        }
    }
    
    // Load User Data from CloudKit
    private func loadUserData() {
        guard !userRecordID.isEmpty else {
            print("No saved recordID found.")
            return
        }

        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: userRecordID)

        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("Error fetching user record by recordID: \(error.localizedDescription)")
            } else if let userRecord = record {
                DispatchQueue.main.async {
                    self.userFullName = userRecord["fullName"] as? String ?? "Unknown"
                    self.userEmail = userRecord["email"] as? String ?? "Unknown"
                    print("User data loaded: \(self.userFullName), \(self.userEmail)")
                }
            }
        }
    }
    
    // Save Reminder Time to CloudKit
    private func saveReminderTimeToCloudKit(newTime: Date) {
        guard !userRecordID.isEmpty else {
            print("No saved recordID found.")
            return
        }

        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: userRecordID)

        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("Error fetching user record to update reminder time: \(error.localizedDescription)")
            } else if let userRecord = record {
                userRecord["reminderTime"] = newTime as NSDate

                database.save(userRecord) { _, saveError in
                    if let saveError = saveError {
                        print("Error saving reminder time to CloudKit: \(saveError.localizedDescription)")
                    } else {
                        print("Reminder time updated in CloudKit: \(newTime)")
                    }
                }
            }
        }
    }
    
    // Fetch Reminder Time from CloudKit
    private func fetchReminderTimeFromCloudKit() {
        guard !userRecordID.isEmpty else {
            print("No saved recordID found.")
            return
        }

        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: userRecordID)

        database.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("Error fetching reminder time from CloudKit: \(error.localizedDescription)")
            } else if let userRecord = record, let savedReminderTime = userRecord["reminderTime"] as? Date {
                DispatchQueue.main.async {
                    self.reminderTime = savedReminderTime
                    print("Reminder time loaded: \(savedReminderTime)")
                }
            } else {
                print("No reminder time found in CloudKit.")
            }
        }
    }
    
    // Schedule Notification
    private func scheduleNotification(for time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyJournalReminder"]) // Remove old reminders

        let content = UNMutableNotificationContent()
        content.title = "Daily Journal Reminder"
        content.body = "Don't forget to enter your daily journal entry!"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        let request = UNNotificationRequest(identifier: "dailyJournalReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Daily journal reminder scheduled at \(time)")
            }
        }
    }
    
    // Check Notification Permission
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                DispatchQueue.main.async {
                    self.showNotificationPermissionAlert = true
                }
            }
        }
    }
    
    // Log Out Action
    private func logOut() {
        isLoggedIn = false
        // Let CloudKit re-fetch `userFullName` and `userEmail` during the next login.
    }
}
