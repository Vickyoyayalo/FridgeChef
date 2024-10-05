//
//  SectionTitleView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/05.
//

import SwiftUI

struct SectionTitleView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("ArialRoundedMTBold", size: 20))
                .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
            
            Spacer()

        }
    }
}
