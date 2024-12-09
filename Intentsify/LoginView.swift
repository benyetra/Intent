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
                if let email = appleIDCredential.email {
                    userEmail = email
                }
                saveUserInCloudKit(userEmail: userEmail)
                isLoggedIn = true
            }
        case .failure(let error):
            print("Sign-in failed: \(error.localizedDescription)")
        }
    }
    
    private func saveUserInCloudKit(userEmail: String) {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        let userRecord = CKRecord(recordType: "User")
        userRecord["email"] = userEmail
        
        database.save(userRecord) { _, error in
            if let error = error {
                print("Error saving user to CloudKit: \(error.localizedDescription)")
            } else {
                print("User saved to CloudKit")
            }
        }
    }
    
    private func checkiCloudAvailability() {
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                print("iCloud account error: \(error.localizedDescription)")
            } else {
                if status == .noAccount {
                    print("No iCloud account is logged in.")
                } else {
                    print("iCloud is ready.")
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
