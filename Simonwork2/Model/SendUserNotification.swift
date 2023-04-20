//
//  GuideModel.swift
//  Simonwork2
//
//  Created by Sangmok Choi on 2023/04/02.
//

import Foundation
import UIKit
import UserNotifications

class SendUserNotification {
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    func requestNotificationAuthorization() {
        let userNotificationCenter = UNUserNotificationCenter.current()
        let authOptions = UNAuthorizationOptions(arrayLiteral: .alert, .sound)
        userNotificationCenter.requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print("Error: \(error)")
            } 
        }
    }
    
    func letterSendingPush(){ // 오늘 편지를 보냈는지 확인하는 함수
        
        let currentDate = Date()
        let latesetLetterSentDate = UserDefaults.shared.object(forKey: "todayLetterUpdateTime") as? Date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC") // UTC 시간대로 설정
        
        let todayDate = dateFormatter.string(from: currentDate)
        let todayLetterSent = dateFormatter.string(from: latesetLetterSentDate ?? Date())
    
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: currentDate, to: latesetLetterSentDate ?? Date())
        
        let daysDifference = components.day ?? 0 // 오늘 날짜와 편지가 작성된 날짜 사이의 일자를 구함
        
        if daysDifference == 0 {
            // notification 미발송
        } else if case 1...3 = daysDifference { // 마지막 편지 발송이 1~3일인 경우 노티 발송
            // notification 발송
            let notiContent1 = UNMutableNotificationContent() // 푸시알림 컨텐츠 넣는 클래스

            notiContent1.title = "밤편지"
            notiContent1.body = "답장을 기다리고 있는 상대방에게 밤편지를 전해주세요."
            
            let TimeIntervalTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request1 = UNNotificationRequest(identifier: "intervalTimerDone",
                                                content: notiContent1,
                                                trigger: TimeIntervalTrigger)
            // 알림센터에 추가
            userNotificationCenter.add(request1) { error in
                if let error = error {
                    print("Notification Error: ", error)
                }
            }
        } else if case 7 = daysDifference {
            // notification 발송
            let notiContent2 = UNMutableNotificationContent() // 푸시알림 컨텐츠 넣는 클래스

            notiContent2.title = "자정이 되기까지 10분 전이에요"
            notiContent2.body = "편지를 보낼 수 있는 시간이 얼마 안 남았어요!"
            
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: currentDate)
            dateComponents.hour = 23 // 11pm
            dateComponents.minute = 0

            // Create a UNCalendarNotificationTrigger with the updated date components
            let calendarNotificationTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true) // 오후 11시에 푸시 알림 보내는 트리거
            let request2 = UNNotificationRequest(identifier: "elevenDone",
                                                content: notiContent2,
                                                trigger: calendarNotificationTrigger)
            userNotificationCenter.add(request2) { error in
                if let error = error {
                    print("Notification Error: ", error)
                }
            }
        } else {
            // notification 미발송
        }
    }

}
