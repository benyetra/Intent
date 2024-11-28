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

    var body: some View {
        Form {
            if let user = userInfo.first {
                Section(header: Text("Account Details")) {
                    Text("Signed in as \(user.fullName ?? "Unknown User")")
                    Text(user.email ?? "No email available")
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
    }

    private func configureSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                appleUserIdentifier = credential.user
                saveUserInfo(credential: credential)
            }
        case .failure(let error):
            print("Sign in failed: \(error.localizedDescription)")
        }
    }

    private func saveUserInfo(credential: ASAuthorizationAppleIDCredential) {
        let user = UserInfo(context: viewContext)
        user.id = UUID()
        user.fullName = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        user.email = credential.email
        user.appleUserIdentifier = credential.user
        try? viewContext.save()
    }

    private func signOut() {
        // Clear user information
        appleUserIdentifier = nil
        userInfo.forEach(viewContext.delete)
        try? viewContext.save()
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
