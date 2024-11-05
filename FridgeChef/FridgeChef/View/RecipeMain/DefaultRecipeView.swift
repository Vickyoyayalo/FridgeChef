//
//  DefaultRecipeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/06.
//

import SwiftUI

struct DefaultRecipeView: View {
    @State private var moveUp = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    ZStack {
                        Image("discomonster3")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 400)
                            .shadow(radius: 10)
                            .offset(y: moveUp ? -50 : 50)
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatForever(autoreverses: true),
                                value: moveUp
                            )
                            .onAppear {
                                moveUp = true
                            }
                    }
                    
                    Text("Looking for inspiration? \nEnter a keyword to get started!")
                        .font(.custom("Menlo-BoldItalic", size: 17))
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.systemOrange))
                        .fontWeight(.bold)
                        .padding(.top, 15)
                        .shadow(radius: 10)
                }
                .padding(.horizontal, 16)
            }
        }
        .scrollIndicators(.hidden)
    }
}

