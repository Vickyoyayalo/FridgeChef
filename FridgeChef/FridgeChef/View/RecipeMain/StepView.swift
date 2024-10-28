//
//  StepView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
//

import SwiftUI

struct StepView: View {
    let step: Step

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(step.number).")
                .font(.custom("ArialRoundedMTBold", size: 18)) 
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? .orange))
            Text(step.step)
                .foregroundColor(.gray)
                .font(.custom("ArialRoundedMTBold", size: 18))
        }
        .padding(.vertical, 5)
    }
}
