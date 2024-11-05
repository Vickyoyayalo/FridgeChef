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
    let primaryColor: Color
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
                .font(.custom("ArialRoundedMTBold", size: 18)) 
                .foregroundColor(primaryColor)
            Text(text)
                .foregroundColor(.gray)
                .font(.custom("ArialRoundedMTBold", size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
