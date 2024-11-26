//
//  MonsterAnimationView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import SwiftUI
import Foundation

struct MonsterAnimationView: View {
    @State private var moveRight = false
    
    var body: some View {
        ZStack {
            Image("runmonster")
                .resizable()
                .frame(width: 100, height: 100)
                .offset(x: moveRight ? 180 : -150)
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: moveRight)
            
            Image("RUNchicken")
                .resizable()
                .frame(width: 60, height: 60)
                .offset(x: moveRight ? 120 : -280)
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: moveRight)
        }
        .onAppear {
            moveRight = true
            print("Animation1 started")
        }
        .onDisappear {
            moveRight = false
            print("Animation1 stopped")
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                moveRight = true // Start animation
            }
            print("Animation2 started")
        }
        .onDisappear {
            withAnimation(nil) {
                moveRight = false
            }
            print("Animation2 stopped")
        }
    }
}
