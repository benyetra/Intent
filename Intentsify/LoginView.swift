//
//  LoginView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//
import SwiftUI
import AuthenticationServices
import CloudKit

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userEmail") private var userEmail: String = ""

    var body: some View {
        ZStack {
            Color("LightBackgroundColor").ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer() // Push content towards the center

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Text("Welcome to\nIntentsify")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("ReverseAccentColor"))
                            .multilineTextAlignment(.center)

                        Image(systemName: "apple.meditate.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40) // Adjust size as needed
                            .foregroundColor(Color("ReverseAccentColor")) // Fill the system image with yellow
                    }
                    .multilineTextAlignment(.center)

                    Text("Track your goals and build momentum towards positive change.")
                        .font(.subheadline)
                        .foregroundColor(Color("ReverseAccentColor"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Spacer() // Push title and subtitle to the center

                // Sign In Button
                SignInWithAppleButton(
                    .signIn,
                    onRequest: configureSignInWithAppleRequest,
                    onCompletion: handleSignInWithAppleCompletion
                )
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 50)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color("AccentColor"), lineWidth: 2)
                )
                .shadow(color: Color("AccentColor").opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)

                // Security Text
                Text("Sign in securely with your Apple ID")
                    .font(.footnote)
                    .foregroundColor(Color("ReverseAccentColor"))

                Spacer()

                // Footer
                Text("Powered by YetiApps")
                    .font(.footnote)
                    .foregroundColor(Color("ReverseAccentColor"))
            }
            .padding()
        }
        .onAppear {
            checkiCloudAvailability()
        }
    }

    private func configureSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let fullName = [
                    appleIDCredential.fullName?.givenName,
                    appleIDCredential.fullName?.familyName
                ]
                .compactMap { $0 }
                .joined(separator: " ")
                let email = appleIDCredential.email ?? "Hidden"

                print("Apple ID User ID: \(userID)")
                print("Full Name: \(fullName)")
                print("Email: \(email)")

                // Save user details in CloudKit
                saveUserInCloudKit(userEmail: email, fullName: fullName, userID: userID)

                isLoggedIn = true
            }
        case .failure(let error):
            print("Sign-in failed: \(error.localizedDescription)")
        }
    }

    @AppStorage("userRecordID") private var userRecordID: String = ""

    private func saveUserInCloudKit(userEmail: String, fullName: String, userID: String) {
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase

        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "userID == %@", userID))
        database.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                print("Error fetching user record: \(error.localizedDescription)")
            } else if let existingRecord = results?.first {
                DispatchQueue.main.async {
                    self.userRecordID = existingRecord.recordID.recordName
                }
            } else {
                let userRecord = CKRecord(recordType: "User")
                userRecord["userID"] = userID
                userRecord["email"] = userEmail
                userRecord["fullName"] = fullName

                database.save(userRecord) { savedRecord, saveError in
                    if let saveError = saveError {
                        print("Error saving user: \(saveError.localizedDescription)")
                    } else if let savedRecord = savedRecord {
                        DispatchQueue.main.async {
                            self.userRecordID = savedRecord.recordID.recordName
                        }
                    }
                }
            }
        }
    }

    private func checkiCloudAvailability() {
        let container = CKContainer(identifier: "iCloud.intentsify")
        container.accountStatus { status, error in
            if let error = error {
                print("iCloud error: \(error.localizedDescription)")
            } else {
                switch status {
                case .noAccount:
                    print("No iCloud account logged in.")
                case .restricted:
                    print("iCloud is restricted.")
                case .available:
                    print("iCloud is available.")
                default:
                    print("Unknown iCloud status.")
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
