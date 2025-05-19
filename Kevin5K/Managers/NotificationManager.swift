//
//  NotificationManager.swift
//  Kevin5K
//
//  Created by Kevin Byers on 2/5/2025.
//


import UserNotifications
import Foundation

struct NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func scheduleAll(for sessions: [Session]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        for s in sessions {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: s.date)
            comps.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = "Today's workout"
            content.body  = s.title
            
            let request = UNNotificationRequest(
                identifier: s.id.uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
