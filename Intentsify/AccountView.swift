//
//  AccountsView.swift
//  Intentsify
//
//  Created by Bennett Yetra on 11/26/24.
//

import SwiftUI

struct AccountView: View {
    @State private var notificationTime = Date()

    var body: some View {
        Form {
            Section(header: Text("Notification Settings")) {
                DatePicker("Reminder Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    .onChange(of: notificationTime) { newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        scheduleDailyNotification(time: components)
                    }
            }
        }
    }
}

#Preview {
    AccountView()
}
