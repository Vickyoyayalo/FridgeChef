//
//  FeatureRowView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/6.
//

import SwiftUI

struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }
}

struct FeatureRowView_Previews: PreviewProvider {
    static var previews: some View {
        FeatureRowView(icon: "leaf", title: "智能食材管理", description: "管理你的食材，避免浪費。")
            .previewLayout(.sizeThatFits)
    }
}

