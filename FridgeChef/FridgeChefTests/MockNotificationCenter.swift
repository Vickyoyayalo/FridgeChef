//
//  MockUNUserNotificationCenter.swift
//  FridgeChefTests
//
//  Created by Vickyhereiam on 2024/10/23.
//

import Foundation
@testable import FridgeChef
import UserNotifications

class MockNotificationCenter: NotificationCenterProtocol {
    var addCallCount = 0
    var lastAddedRequest: UNNotificationRequest?
    var requests: [UNNotificationRequest] = []
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        addCallCount += 1
        lastAddedRequest = request
        requests.append(request)
        completionHandler?(nil)
    }
}
