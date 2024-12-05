//
//  AccountView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 11/26/24.
//

import SwiftUI
import CoreData
import AuthenticationServices

struct AccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("appleUserIdentifier") private var appleUserIdentifier: String?
    @FetchRequest(entity: UserInfo.entity(), sortDescriptors: []) private var userInfo: FetchedResults<UserInfo>

    @State private var showEditAccountDetails: Bool = false

    var body: some View {
        Form {
            if let user = userInfo.first {
                Section(header: Text("Account Details")) {
                    Text("Signed in as \(user.fullName ?? "Name unavailable")")
                    Text(user.email ?? "Email unavailable")

                    if user.fullName == nil || user.email == nil {
                        Button(action: { showEditAccountDetails = true }) {
                            Text("Update Account Details")
                                .foregroundColor(.blue)
                        }
                    }

                    Button(action: signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Section(header: Text("Account")) {
                    SignInWithAppleButton(.signIn, onRequest: configureSignInRequest, onCompletion: handleSignIn)
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                }
            }
        }
        .sheet(isPresented: $showEditAccountDetails) {
            if let user = userInfo.first {
                UpdateUserInfoView(user: user)
            }
        }
    }

    private func configureSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                appleUserIdentifier = credential.user

                do {
                    try viewContext.saveUserInfo(credential: credential)
                } catch {
                    print("Error saving user info locally: \(error.localizedDescription)")
                }

                // Automatically show edit view if details are incomplete
                if let user = userInfo.first, (user.fullName == nil || user.email == nil) {
                    showEditAccountDetails = true
                }
            }
        case .failure(let error):
            print("Sign in failed: \(error.localizedDescription)")
        }
    }


    private func signOut() {
        appleUserIdentifier = nil
        userInfo.forEach(viewContext.delete)

        do {
            try viewContext.save()
            print("Successfully signed out.")
        } catch {
            print("Failed to save context during sign-out: \(error.localizedDescription)")
        }
    }
}

struct ReminderSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("appleUserIdentifier") private var appleUserIdentifier: String?
    @FetchRequest(
        entity: ReminderSettings.entity(),
        sortDescriptors: []
    ) private var reminderSettings: FetchedResults<ReminderSettings>
    
    @State private var notificationTime = Date()
    
    var body: some View {
        Form {
            Section(header: Text("Notification Settings")) {
                DatePicker("Reminder Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    .onChange(of: notificationTime) { newValue in
                        saveReminderTime(newValue)
                    }
            }
        }
        .onAppear {
            if let settings = reminderSettings.first {
                notificationTime = settings.notificationTime ?? Date()
            }
        }
    }

    private func saveReminderTime(_ time: Date) {
        let settings = reminderSettings.first ?? ReminderSettings(context: viewContext)
        settings.id = settings.id ?? UUID()
        settings.notificationTime = time
        settings.userId = appleUserIdentifier
        try? viewContext.save()
    }
}

// MARK: - Notification Scheduling Helper
private func scheduleDailyNotification(at time: Date) {
    let content = UNMutableNotificationContent()
    content.title = "Daily Reminder"
    content.body = "Don't forget to check your journal!"
    content.sound = .default

    var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

    let request = UNNotificationRequest(identifier: "DailyReminder", content: content, trigger: trigger)

    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests() // Avoid duplicates
    center.add(request)
}

#Preview {
    AccountView()
}
