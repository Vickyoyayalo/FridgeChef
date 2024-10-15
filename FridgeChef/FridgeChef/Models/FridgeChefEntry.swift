//
//  FridgeChefEntry.swift
//  FridgeChefWidgetExtension
//
//  Created by Vickyhereiam on 2024/10/8.
//

import WidgetKit
import SwiftUI

struct FridgeChefWidgetEntry: TimelineEntry {
    let date: Date
    let ingredientName: String
}

struct FridgeChefWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FridgeChefWidgetEntry {
        FridgeChefWidgetEntry(date: Date(), ingredientName: "No Expiring Items")
    }

    func getSnapshot(in context: Context, completion: @escaping (FridgeChefWidgetEntry) -> ()) {
        let entry = FridgeChefWidgetEntry(date: Date(), ingredientName: "Carrots expiring in 2 days")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FridgeChefWidgetEntry>) -> ()) {
        var entries: [FridgeChefWidgetEntry] = []
        let currentDate = Date()
        // 每小時更新一次 widget
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = FridgeChefWidgetEntry(date: entryDate, ingredientName: "Carrots expiring in 2 days")
            entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct FridgeChefWidgetView: View {
    var entry: FridgeChefWidgetProvider.Entry

    var body: some View {
        VStack {
            Text("FridgeChef")
                .font(.headline)
            Text("Next item expiring: \(entry.ingredientName)")
                .font(.subheadline)
        }
    }
}

