//
//  ProgressOverlay.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/3.
//

import Foundation
import SwiftUI

struct ProgressOverlay: View {
    var showing: Bool
    var message: String
    
    var body: some View {
        Group {
            if showing {
                VStack {
                    ProgressView()
                    Text(message)
                        .font(.caption)
                        .padding(.top, 5)
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .fontWeight(.bold)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.bottom, 50)
            }
        }
    }
}

