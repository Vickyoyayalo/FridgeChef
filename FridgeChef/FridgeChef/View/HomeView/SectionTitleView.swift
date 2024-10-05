//
//  SectionTitleView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
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
            
//            Text("See All")
//                .foregroundColor(Color("PrimaryColor"))
//                .onTapGesture {
//                    
//                }
        }
    }
}
