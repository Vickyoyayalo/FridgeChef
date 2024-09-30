//
//  CustomBackButtonModifier.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//
//import SwiftUI
//
//struct CustomNavigationBarView<Content: View>: View {
//    @Environment(\.presentationMode) var presentationMode
//    let content: Content
//    let title: String
//    
//    init(title: String, @ViewBuilder content: () -> Content) {
//        self.title = title
//        self.content = content()
//    }
//    
//    var body: some View {
//        VStack {
//            content
//        }
//        .navigationBarBackButtonHidden(true)
//        .navigationBarItems(leading: Button(
//            action: {
//        self.presentationMode.wrappedValue.dismiss()
//        }) {
//            Image(systemName: "arrowshape.turn.up.backward.circle.fill")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .imageScale(.large)
//        })
//        .navigationBarTitle(Text(title), displayMode: .inline)
//    }
//}
import SwiftUI

struct CustomNavigationBarView<Content: View>: View {
    @Environment(\.presentationMode) var presentationMode
    let content: Content
    let title: String
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 漸層背景
            LinearGradient(
                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.4)
            .edgesIgnoringSafeArea(.all)

            VStack {
                content
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitle(Text(title), displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrowshape.turn.up.backward.circle.fill")
                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                    .imageScale(.large)
            })
        }
    }
}

// 父視圖中使用 CustomNavigationBarView 並隱藏預設導航欄
struct ParentView: View {
    var body: some View {
        NavigationView {
            CustomNavigationBarView(title: "FridgeChef") {
                // 內容
                Text("Your content here")
            }
            .navigationBarHidden(true)  // 隱藏預設導航欄
        }
    }
}
