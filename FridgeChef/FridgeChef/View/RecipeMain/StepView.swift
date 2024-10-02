//
//  StepView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
//

import SwiftUI

struct StepView: View {
    let step: Step // 假設 Step 已經定義好

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) { // 使用 firstTextBaseline
            Text("\(step.number).")
                .font(.custom("ArialRoundedMTBold", size: 18)) // 調整字體大小與內容一致
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? .orange))
            Text(step.step)
                .foregroundColor(.gray)
                .font(.custom("ArialRoundedMTBold", size: 18))
        }
        .padding(.vertical, 5)
    }
}
