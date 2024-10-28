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
                .font(.custom("ArialRoundedMTBold", size: 20))
                .foregroundColor(.black)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.vertical, 5)

            content
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(8)
        .padding(.horizontal, 5)
    }
}
