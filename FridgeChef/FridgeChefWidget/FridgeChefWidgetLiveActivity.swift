//
//  FridgeChefWidgetLiveActivity.swift
//  FridgeChefWidget
//
//  Created by Vickyhereiam on 2024/10/8.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FridgeChefWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FridgeChefWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FridgeChefWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FridgeChefWidgetAttributes {
    fileprivate static var preview: FridgeChefWidgetAttributes {
        FridgeChefWidgetAttributes(name: "World")
    }
}

extension FridgeChefWidgetAttributes.ContentState {
    fileprivate static var smiley: FridgeChefWidgetAttributes.ContentState {
        FridgeChefWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FridgeChefWidgetAttributes.ContentState {
         FridgeChefWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FridgeChefWidgetAttributes.preview) {
   FridgeChefWidgetLiveActivity()
} contentStates: {
    FridgeChefWidgetAttributes.ContentState.smiley
    FridgeChefWidgetAttributes.ContentState.starEyes
}
