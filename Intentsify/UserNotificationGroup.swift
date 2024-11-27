//
//  UserNotificationGroup.swift
//  Intentsify
//
//  Created by Bennett Yetra on 11/25/24.
//

import UserNotifications

func scheduleDailyNotification(time: DateComponents) {
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
        if granted {
            let content = UNMutableNotificationContent()
            content.title = "Daily Reminder"
            content.body = "Don't forget to log your Intentsify!"
            content.sound = .default
            
            var triggerDate = time
            triggerDate.calendar = Calendar.current
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
            
            let request = UNNotificationRequest(identifier: "DailyReminder", content: content, trigger: trigger)
            notificationCenter.add(request)
        }
    }
}
