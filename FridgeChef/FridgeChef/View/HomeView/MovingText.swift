//
//  MovingText.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/7.
//

import SwiftUI

struct MovingTextView: View {
    @State private var offsetX: CGFloat = -30 // 初始的左移位移
    @State private var showClickMe = true // 控制 "Click me" 的動畫狀態
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // "What would you like to cook today?" 左右擺動
            Text("What would you like to cook today?")
                .padding(.horizontal)
                .foregroundColor(.orange)
                .font(.custom("Menlo-BoldItalic", size: 25))
                .shadow(radius: 8)
                .offset(x: offsetX) // 使用 offset 來控制文字位置
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        offsetX = 30 // 讓文字不斷從左到右擺動
                    }
                }

            // 左上角的 "Click me" 動畫提示
            Text("Click me")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .opacity(showClickMe ? 1 : 0) // 根據動畫狀態控制透明度
                .scaleEffect(showClickMe ? 1.2 : 1.0) // 放大縮小效果
                .offset(x: -30, y: -30) // 調整 "Click me" 的位置
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        showClickMe.toggle() // 閃爍動畫
                    }
                }
        }
    }
}

struct FloatingButtonView: View {
    @State private var isShowingGameView = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Floating Button with Image
            Button(action: {
                isShowingGameView = true
            }) {
                Image("himonster")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
            }
            .padding(.trailing, -10)
            .padding(.top, 60)

            // Moving Text with "Click me"
            MovingTextView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButtonView()
    }
}

