//
//  SignInView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/4/24.
//

import SwiftUI
import AuthenticationServices
import CoreData

struct SignInView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("appleUserIdentifier") private var appleUserIdentifier: String?

    var body: some View {
        VStack {
            Text("Welcome to Intentsify")
                .font(.largeTitle)
                .padding()

            SignInWithAppleButton(.signIn, onRequest: configureSignInRequest, onCompletion: handleSignIn)
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(10)
                .padding()
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

                // Save user info
                do {
                    try viewContext.saveUserInfo(credential: credential)
                } catch {
                    print("Error saving user info: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            print("Sign in failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SignInView()
}
