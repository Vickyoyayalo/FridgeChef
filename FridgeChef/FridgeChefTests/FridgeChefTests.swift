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
        // Arrange
        let mockNotificationCenter = MockNotificationCenter()
       
        let expirationDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let item = FoodItem(id: "1", name: "Milk", quantity: 1, unit: "瓶", status: .fridge, expirationDate: expirationDate, imageURL: nil)
        
        // Act
        let fridgeView = FridgeView(foodItemStore: FoodItemStore())
        fridgeView.scheduleExpirationNotification(for: item, notificationCenter: mockNotificationCenter)
        
        // Assert
        XCTAssertEqual(mockNotificationCenter.addCallCount, 1, "add() should be called once")
        XCTAssertNotNil(mockNotificationCenter.lastAddedRequest, "The notification request should be created")
        XCTAssertEqual(mockNotificationCenter.lastAddedRequest?.content.title, "Expiration Alert‼️")
        XCTAssertEqual(mockNotificationCenter.lastAddedRequest?.content.body, "Milk is about to expire in 2 days!")
        
        if let trigger = mockNotificationCenter.lastAddedRequest?.trigger as? UNTimeIntervalNotificationTrigger {
            XCTAssertEqual(trigger.timeInterval, 2 * 24 * 60 * 60, accuracy: 1.0)
        } else {
            XCTFail("Trigger is not of expected type")
        }
    }
    
    func testExpiredItemNotification() {
        // Arrange
        let mockNotificationCenter = MockNotificationCenter()
       
        let expirationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let expiredItem = FoodItem(id: "2", name: "Expired Cheese", quantity: 1, unit: "片", status: .fridge, expirationDate: expirationDate, imageURL: nil)
        
        // Act
        let fridgeView = FridgeView(foodItemStore: FoodItemStore())
        fridgeView.scheduleExpirationNotification(for: expiredItem, notificationCenter: mockNotificationCenter)
        
        // Assert
        XCTAssertEqual(mockNotificationCenter.addCallCount, 1, "add() should be called once for an expired item")
        XCTAssertEqual(mockNotificationCenter.lastAddedRequest?.content.title, "Expired Alert‼️")
        XCTAssertEqual(mockNotificationCenter.lastAddedRequest?.content.body, "Expired Cheese expired 1 day ago!")
        
        if let trigger = mockNotificationCenter.lastAddedRequest?.trigger as? UNTimeIntervalNotificationTrigger {
            XCTAssertEqual(trigger.timeInterval, 1, "The trigger time interval should be immediate for expired items")
        } else {
            XCTFail("Trigger is not of expected type")
        }
    }
    
    func testScheduleNotificationsForExpiringAndExpiredItems() {
        // Arrange
        let mockNotificationCenter = MockNotificationCenter()
      
        let expiringExpirationDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let expiringItem = FoodItem(id: "1", name: "Yogurt", quantity: 1, unit: "瓶", status: .fridge, expirationDate: expiringExpirationDate, imageURL: nil)
        
        let expiredExpirationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let expiredItem = FoodItem(id: "2", name: "Cheese", quantity: 1, unit: "片", status: .fridge, expirationDate: expiredExpirationDate, imageURL: nil)
        
        // Act
        let fridgeView = FridgeView(foodItemStore: FoodItemStore())
        fridgeView.scheduleExpirationNotification(for: expiredItem, notificationCenter: mockNotificationCenter)
        fridgeView.scheduleExpirationNotification(for: expiringItem, notificationCenter: mockNotificationCenter)
        
        // Assert
        XCTAssertEqual(mockNotificationCenter.addCallCount, 2, "Two notifications should be scheduled (for expiring and expired items)")
        
        XCTAssertEqual(mockNotificationCenter.requests[0].content.body, "Cheese expired 1 day ago!")
        XCTAssertEqual(mockNotificationCenter.requests[1].content.body, "Yogurt is about to expire in 2 days!")
    }
    
    func testImmediateNotificationForExpiredItem() {
        let mockNotificationCenter = MockNotificationCenter()
        let expirationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let expiredItem = FoodItem(id: "1", name: "Expired Milk", quantity: 1, unit: "瓶", status: .fridge, expirationDate: expirationDate, imageURL: nil)
        
        let fridgeView = FridgeView(foodItemStore: FoodItemStore())
        fridgeView.scheduleExpirationNotification(for: expiredItem, notificationCenter: mockNotificationCenter)
        
        XCTAssertEqual(mockNotificationCenter.addCallCount, 1, "Notification should be added immediately for expired item")
        XCTAssertEqual(mockNotificationCenter.lastAddedRequest?.content.body, "Expired Milk expired 1 day ago!")
    }
    
    func testScheduledNotificationForExpiringItem() {
        let mockNotificationCenter = MockNotificationCenter()
        let expirationDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let expiringItem = FoodItem(id: "2", name: "Yogurt", quantity: 1, unit: "瓶", status: .fridge, expirationDate: expirationDate, imageURL: nil)
        
        let fridgeView = FridgeView(foodItemStore: FoodItemStore())
        fridgeView.scheduleExpirationNotification(for: expiringItem, notificationCenter: mockNotificationCenter)
        
        XCTAssertEqual(mockNotificationCenter.addCallCount, 1, "Notification should be scheduled for expiring item")
        XCTAssertEqual(mockNotificationCenter.lastAddedRequest?.content.body, "Yogurt is about to expire in 2 days!")
    }
}

class GroceryNotificationTests: XCTestCase {
    
    func testScheduleToBuyNotification() {
        // Arrange
        let mockNotificationCenter = MockNotificationCenter()
        let item = FoodItem(id: "1", name: "Apples", quantity: 5, unit: "個", status: .toBuy, expirationDate: nil, imageURL: nil)
        
        // Act
        let groceryListView = GroceryListView(foodItemStore: FoodItemStore())
        groceryListView.scheduleToBuyNotification(for: item, notificationCenter: mockNotificationCenter)
        
        // Assert
        XCTAssertEqual(mockNotificationCenter.addCallCount, 1, "add() should be called once for to-buy notification")
        
        let request = mockNotificationCenter.lastAddedRequest
        XCTAssertEqual(request?.content.title, "Grocery Reminder")
        XCTAssertEqual(request?.content.body, "Don't forget to buy Apples!")
        XCTAssertEqual(request?.identifier, "1")
        
        if let trigger = request?.trigger as? UNTimeIntervalNotificationTrigger {
            XCTAssertEqual(trigger.timeInterval, 3600, accuracy: 1.0, "The trigger time interval should be 1 hour")
        } else {
            XCTFail("Trigger is nil or not of expected type")
        }
    }
}

class FoodItemTests: XCTestCase {
    func testDaysRemaining() {
        let calendar = Calendar.current
        
        let fiveDaysLater = calendar.date(byAdding: .day, value: 5, to: Date())!
        let foodItem = FoodItem(id: "1", name: "Milk", quantity: 1.0, unit: "L", status: .fridge, expirationDate: fiveDaysLater, imageURL: nil)
        
        XCTAssertEqual(foodItem.daysRemaining, 5)
       
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!
        let expiredFoodItem = FoodItem(id: "2", name: "Cheese", quantity: 0.5, unit: "kg", status: .freezer, expirationDate: threeDaysAgo, imageURL: nil)
        
        XCTAssertEqual(expiredFoodItem.daysRemaining, -3)
        
        let noExpirationFoodItem = FoodItem(id: "3", name: "Rice", quantity: 2.0, unit: "kg", status: .toBuy, expirationDate: nil, imageURL: nil)
        
        XCTAssertEqual(noExpirationFoodItem.daysRemaining, 0)
    }
}
