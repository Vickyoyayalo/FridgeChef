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
        HStack(alignment: .top, spacing: 10) {
            Text("\(step.number).")
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? .orange))
            Text(step.step)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

