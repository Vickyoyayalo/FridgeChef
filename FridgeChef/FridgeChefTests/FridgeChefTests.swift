//
//  FridgeChefTests.swift
//  FridgeChefTests
//
//  Created by Vickyhereiam on 2024/10/23.
//
import XCTest
import UserNotifications
@testable import FridgeChef

class NotificationTests: XCTestCase {

    func testScheduleExpirationNotification() {
        // Arrange: 準備 FoodItem 和 Mock Notification Center
        let mockNotificationCenter = MockNotificationCenter()
        let item = FoodItem(id: "1", name: "Milk", quantity: 1, unit: "瓶", status: .fridge, daysRemaining: 2, expirationDate: Date(), imageURL: nil)
        
        // Act: 調用 scheduleExpirationNotification 通過 FridgeView 的實例
        let fridgeView = FridgeView()
        fridgeView.scheduleExpirationNotification(for: item, notificationCenter: mockNotificationCenter)
        
        // Assert: 確認通知被調用
        XCTAssertEqual(mockNotificationCenter.addCallCount, 1, "add() should be called once")
        XCTAssertNotNil(mockNotificationCenter.lastAddedRequest, "The notification request should be created")
        
        // Assert: 檢查通知內容
        let request = mockNotificationCenter.lastAddedRequest
        XCTAssertEqual(request?.content.title, "Expiration Alert‼️")
        XCTAssertEqual(request?.content.body, "Milk is about to expire in 2 days!")
        XCTAssertEqual(request?.identifier, "1")
        
        // Assert: 檢查通知的時間間隔
        if let trigger = request?.trigger as? UNTimeIntervalNotificationTrigger {
            XCTAssertEqual(trigger.timeInterval, 2 * 24 * 60 * 60, accuracy: 1.0)
        } else {
            XCTFail("Trigger is nil or not of expected type")
        }
    }
    
    func testScheduleNotificationWithInvalidTimeInterval() {
        // Arrange: 準備一個過期的食材
        let mockNotificationCenter = MockNotificationCenter()
        let item = FoodItem(id: "1", name: "Expired Milk", quantity: 1, unit: "瓶", status: .fridge, daysRemaining: 0, expirationDate: Date(), imageURL: nil)
        
        // Act: 調用 scheduleExpirationNotification，這次不應該調用 add()
        let fridgeView = FridgeView() 
        fridgeView.scheduleExpirationNotification(for: item, notificationCenter: mockNotificationCenter)
        
        // Assert: 檢查是否沒有調用 add()
        XCTAssertEqual(mockNotificationCenter.addCallCount, 0, "add() should not be called for an expired item")
    }
}
