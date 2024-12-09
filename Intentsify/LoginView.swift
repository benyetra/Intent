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
        VStack {
            Spacer()
            Text("Welcome to Intentsify")
                .font(.largeTitle)
                .padding()
            
            SignInWithAppleButton(
                .signIn,
                onRequest: configureRequest,
                onCompletion: handleCompletion
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding()
            
            Spacer()
            Text("Sign in securely with your Apple ID")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .onAppear {
            checkiCloudAvailability()
        }
    }
    
    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                // Always capture the user identifier
                let userID = appleIDCredential.user // Unique identifier for the user
                
                // Handle name and email only if provided
                let fullName = [
                    appleIDCredential.fullName?.givenName,
                    appleIDCredential.fullName?.familyName
                ]
                .compactMap { $0 } // Remove nil values
                .joined(separator: " ") // Combine given and family names
                
                let email = appleIDCredential.email // Email provided only during first login
                
                // Log the captured details for debugging
                print("Apple ID User ID: \(userID)")
                print("Full Name: \(fullName.isEmpty ? "N/A" : fullName)")
                print("Email: \(email ?? "N/A")")
                
                // Save the user details to CloudKit
                saveUserInCloudKit(userEmail: email, fullName: fullName, userID: userID)
                isLoggedIn = true
            }
        case .failure(let error):
            print("Sign-in failed: \(error.localizedDescription)")
        }
    }

    private func saveUserInCloudKit(userEmail: String?, fullName: String?, userID: String) {
        let container = CKContainer(identifier: "iCloud.intentsify")
        let database = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "userID == %@", userID))
        database.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                print("Error fetching user record: \(error.localizedDescription)")
            } else if let existingRecord = results?.first {
                print("User already exists in CloudKit: \(existingRecord)")
            } else {
                // Create a new user record
                let userRecord = CKRecord(recordType: "User")
                userRecord["userID"] = userID
                userRecord["email"] = userEmail ?? "hidden"
                userRecord["fullName"] = fullName ?? "N/A"
                
                database.save(userRecord) { _, saveError in
                    if let saveError = saveError {
                        print("Error saving user to CloudKit: \(saveError.localizedDescription)")
                    } else {
                        print("User saved to CloudKit with userID: \(userID), email: \(userEmail ?? "hidden"), and name: \(fullName ?? "N/A")")
                    }
                }
            }
        }
    }

    
    private func checkiCloudAvailability() {
        let container = CKContainer(identifier: "iCloud.intentsify") // Explicitly set the container ID
        container.accountStatus { status, error in
            if let error = error {
                print("iCloud account error: \(error.localizedDescription)")
            } else {
                switch status {
                case .noAccount:
                    print("No iCloud account is logged in.")
                case .restricted:
                    print("iCloud is restricted.")
                case .available:
                    print("iCloud is ready.")
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
