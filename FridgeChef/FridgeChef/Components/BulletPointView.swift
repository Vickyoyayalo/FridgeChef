//
//  BulletPointView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/2.
//

import Foundation
import SwiftUI

struct BulletPointView: View {
    let text: String
    let primaryColor: Color // 傳入主題色調

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) { // 使用 firstTextBaseline 並增加間距
            Text("•")
                .font(.custom("ArialRoundedMTBold", size: 18)) // 與內容文字統一字體大小
                .foregroundColor(primaryColor)
            Text(text)
                .foregroundColor(.gray)
                .font(.custom("ArialRoundedMTBold", size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

