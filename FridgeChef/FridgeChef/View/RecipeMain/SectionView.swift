//
//  SectionView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
//

import SwiftUI

struct SectionView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .foregroundColor(.black)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.vertical, 5)

            content
        }
        .frame(maxWidth: .infinity)
        .background(Color.white) // 統一背景顏色
        .cornerRadius(15) // 統一圓角大小
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // 統一陰影
        .padding(.horizontal) // 確保與外部容器的間距一致
    }
}
