//
//  TagView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/4.
//

import SwiftUI
import Foundation

struct TagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.custom("ArialRoundedMTBold", size: 15))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.6))
            .foregroundColor(.white)
            .fontWeight(.medium)
            .cornerRadius(8)
    }
}
