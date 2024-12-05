//
//  UpdateUserInfoView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 11/27/24.
//

import SwiftUI
import CoreData
import AuthenticationServices // Import AuthenticationServices to access ASAuthorizationAppleIDCredential

struct UpdateUserInfoView: View {
    @ObservedObject var user: UserInfo
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""

    var body: some View {
        Form {
            Section(header: Text("Update Your Details")) {
                TextField("Full Name", text: $fullName)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
            }

            Button(action: saveUserInfo) {
                Text("Save")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            fullName = user.fullName ?? ""
            email = user.email ?? ""
        }
    }

    private func saveUserInfo() {
        user.fullName = fullName
        user.email = email

        do {
            try viewContext.save()
            dismiss()
            print("User info updated successfully.")
        } catch {
            print("Failed to update user info: \(error.localizedDescription)")
        }
    }
}
