//
//  AccountsView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/9/24.
//

import SwiftUI

import SwiftUI

struct AccountView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userEmail") private var userEmail: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Account")
                    .font(.largeTitle)
                
                if !userEmail.isEmpty {
                    Text("Signed in as:")
                        .font(.headline)
                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Button(action: logout) {
                    Text("Log Out")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Account")
        }
    }
    
    private func logout() {
        isLoggedIn = false
        userEmail = ""
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}


#Preview {
    AccountView()
}
