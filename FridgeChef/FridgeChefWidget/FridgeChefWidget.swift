//
//  FridgeChefWidget.swift
//  FridgeChefWidget
//
//  Created by Vickyhereiam on 2024/10/8.
//

import WidgetKit
import SwiftUI
import Foundation

// 這個 Entry 將會被用來顯示資料
struct SimpleEntry: TimelineEntry {
    let date: Date
    let expiringItems: [SimpleFoodItem]
    let expiredItems: [SimpleFoodItem]
}

struct SimpleFoodItem: Identifiable, Codable {
    var id: String
    var name: String
    var quantity: Double
    var unit: String
    var daysRemaining: Int
    var status: Status // 新增 status 屬性
}

enum Status: String, Codable {
    case toBuy = "toBuy"
    case fridge = "Fridge"
    case freezer = "Freezer"
}

// TimelineProvider：控制 Widget 的刷新頻率和內容
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // 占位資料，用於展示在 Widget 加載之前
        SimpleEntry(date: Date(), expiringItems: [], expiredItems: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        // 快照數據，用於預覽
        let entry = SimpleEntry(date: Date(), expiringItems: mockExpiringItems(), expiredItems: mockExpiredItems())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        
        // 讀取 UserDefaults 中的資料
        let sharedDefaults = UserDefaults(suiteName: "group.com.vickyoyaya.FridgeChef")
        var expiringItems: [SimpleFoodItem] = []
        var expiredItems: [SimpleFoodItem] = []
        
        if let foodItemsData = sharedDefaults?.data(forKey: "foodItems") {
            if let decodedFoodItems = try? JSONDecoder().decode([SimpleFoodItem].self, from: foodItemsData) {
                // 過濾出即將過期或已過期，且狀態為 fridge 或 freezer 的項目
                expiringItems = decodedFoodItems.filter { $0.daysRemaining <= 3 && $0.daysRemaining >= 0 && ($0.status == .fridge || $0.status == .freezer) }
                expiredItems = decodedFoodItems.filter { $0.daysRemaining < 0 && ($0.status == .fridge || $0.status == .freezer) }
            }
        }

        // 創建時間軸條目
        let entry = SimpleEntry(date: currentDate, expiringItems: expiringItems, expiredItems: expiredItems)
        
        // 每小時更新
        let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!))
        completion(timeline)
    }

    
    // 模擬即將過期的項目
    func mockExpiringItems() -> [SimpleFoodItem] {
        return [
            SimpleFoodItem(id: UUID().uuidString, name: "Milk", quantity: 1.0, unit: "Liter", daysRemaining: 2, status: .fridge),
            SimpleFoodItem(id: UUID().uuidString, name: "Eggs", quantity: 12.0, unit: "Pieces", daysRemaining: 1, status: .freezer)
        ]
    }
    
    // 模擬已過期的項目
    func mockExpiredItems() -> [SimpleFoodItem] {
        return [
            SimpleFoodItem(id: UUID().uuidString, name: "Cheese", quantity: 0.5, unit: "Kg", daysRemaining: -2, status: .freezer),
            SimpleFoodItem(id: UUID().uuidString, name: "Yogurt", quantity: 2.0, unit: "Cups", daysRemaining: -1, status: .fridge)
        ]
    }
}

// 主視圖，用於顯示過期和即將過期的食材
struct FridgeChefWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        VStack(alignment: .leading) {
            if entry.expiringItems.isEmpty && entry.expiredItems.isEmpty {
                HStack {
                    Image("Grocerymonster") // Icon for Expiring Soon
                        .resizable()
                        .frame(width: 60, height: 60)
                    Text("No expiring or expired items!")
                        .font(.custom("ArialRoundedMTBold", size: 15))
                        .padding()
                }
            } else {
                switch widgetFamily {
                    
                case .systemSmall:
                    VStack(alignment: .leading, spacing: 10) {
                        if let firstExpiring = entry.expiringItems.first {
                            HStack(alignment: .center, spacing: 5) {
                                Image("runmonster") // Icon for Expiring Soon
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                Text("⚠️ Notice \n\(firstExpiring.name)")
                                    .font(.custom("ArialRoundedMTBold", size: 14))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if let firstExpired = entry.expiredItems.first {
                            HStack(alignment: .center, spacing: 5) {
                                Image("alertmonster") // Icon for Expired
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                Text("Expired‼️ \n\(firstExpired.name)")
                                    .font(.custom("ArialRoundedMTBold", size: 14))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // 確保 VStack 填充整個寬度並左對齊
                    .padding(.leading, -5) // 移除 padding，讓它緊貼左側邊界
                    
                case .systemMedium:
                    let monsterImages = ["mapmonster", "discomonster1", "discomonster2", "discomonster3", "discomonster4", "discomonster5"]
                    let randomMonsterImage = monsterImages.randomElement() ?? "mapmonster" // 隨機選取一個圖片

                    ZStack {
                        VStack(alignment: .leading, spacing: 5) {
                            // Expiring soon section
                            if !entry.expiringItems.isEmpty {
                                HStack(alignment: .center, spacing: 5) {
                                    Text("Expiring soon ⚠️")
                                        .font(.custom("ArialRoundedMTBold", size: 18))
                                        .foregroundColor(.orange)
                                }
                                ForEach(entry.expiringItems.prefix(3), id: \.id) { item in
                                    Text("\(item.name): \(item.daysRemaining) days left")
                                        .font(.custom("ArialRoundedMTBold", size: 15))
                                        .foregroundColor(.orange)
                                }
                                if entry.expiringItems.count > 3 {
                                    Text("...and \(entry.expiringItems.count - 3) more")
                                        .font(.custom("ArialRoundedMTBold", size: 14))
                                        .foregroundColor(.gray)
                                }
                            }

                            // Expired section
                            if !entry.expiredItems.isEmpty {
                                HStack(alignment: .center, spacing: 5) {
                                    Text("Expired ‼️")
                                        .font(.custom("ArialRoundedMTBold", size: 18))
                                        .foregroundColor(.red)
                                }
                                ForEach(entry.expiredItems.prefix(3), id: \.id) { item in
                                    Text("\(item.name): \(abs(item.daysRemaining)) days ago")
                                        .font(.custom("ArialRoundedMTBold", size: 14))
                                        .foregroundColor(.pink)
                                }
                                if entry.expiredItems.count > 3 {
                                    Text("...and \(entry.expiredItems.count - 3) more")
                                        .font(.custom("ArialRoundedMTBold", size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 0)

                        // 在右下角放置隨機選取的圖片
                        VStack {
                            Spacer() // 把圖片推到最下方
                            HStack {
                                Spacer() // 把圖片推到最右邊
                                Image(randomMonsterImage) // 隨機圖片
                                    .resizable()
                                    .frame(width: 100, height: 100) // 調整尺寸
                                    .cornerRadius(10) // 圓角設置
                            }
                        }
                        .padding([.bottom], 20) // 在右下角留一些間距
                    }

                default:
                    Text("Widget not supported.")
                }
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.4)
        }
    }
}


struct FridgeChefWidget: Widget {
    let kind: String = "FridgeChefWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FridgeChefWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fridge Chef Widget")
        .description("Shows food items expiring soon or already expired.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FridgeChefWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for systemSmall
            FridgeChefWidgetEntryView(entry: SimpleEntry(date: Date(), expiringItems: Provider().mockExpiringItems(), expiredItems: Provider().mockExpiredItems()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            // Preview for systemMedium
            FridgeChefWidgetEntryView(entry: SimpleEntry(date: Date(), expiringItems: Provider().mockExpiringItems(), expiredItems: Provider().mockExpiredItems()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
