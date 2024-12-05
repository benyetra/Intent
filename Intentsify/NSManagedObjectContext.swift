//
//  NSManagedObjectContext.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/4/24.
//

import CoreData
import AuthenticationServices

extension NSManagedObjectContext {
    func saveUserInfo(credential: ASAuthorizationAppleIDCredential) throws {
        let fetchRequest: NSFetchRequest<UserInfo> = UserInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "appleUserIdentifier == %@", credential.user)

        let newFullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let newEmail = credential.email

        do {
            if let existingUser = try fetch(fetchRequest).first {
                // Update only if new data is available
                if !newFullName.isEmpty {
                    existingUser.fullName = newFullName
                }
                if let email = newEmail, !email.isEmpty {
                    existingUser.email = email
                }
            } else {
                // Create new user if not found
                let newUser = UserInfo(context: self)
                newUser.id = UUID()
                newUser.appleUserIdentifier = credential.user
                newUser.fullName = newFullName.isEmpty ? nil : newFullName
                newUser.email = newEmail
            }

            // Save context
            try save()
            print("User info saved successfully.")
        } catch {
            print("Failed to save user info: \(error.localizedDescription)")
            throw error
        }
    }
}

