//
//  FloatingMapButton.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/3.
//
import Foundation
import SwiftUI

struct FloatingMapButton: View {
    @Binding var showingMapView: Bool
    @State private var isScaledUp = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingMapView = true
                }) {
                    Image("mapmonster")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .scaleEffect(isScaledUp ? 1.0 : 0.8) // 控制放大縮小比例
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                        )
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .onAppear {
                            isScaledUp.toggle() // 切換放大縮小狀態
                        }
                }
                .sheet(isPresented: $showingMapView) {
                    MapViewWithUserLocation(locationManager: LocationManager(), isPresented: $showingMapView)
                }
                .padding(.trailing, 15)
                .padding(.bottom, 15)
            }
        }
    }
}

struct FloatingMapButton_Previews: PreviewProvider {
    static var previews: some View {
        // 創建一個 @State 變數來模擬 @Binding
        StatefulPreviewWrapper(false) { isShowingMapView in
            FloatingMapButton(showingMapView: isShowingMapView)
        }
    }
}

// 一個用來模擬 @Binding 的包裝器
struct StatefulPreviewWrapper<Content: View>: View {
    @State private var value: Bool
    var content: (Binding<Bool>) -> Content

    init(_ initialValue: Bool, @ViewBuilder content: @escaping (Binding<Bool>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

//import Foundation
//import SwiftUI

//struct FloatingMapButton: View {
//    @Binding var showingMapView: Bool
//    
//    var body: some View {
//        VStack {
//            Spacer()
//            HStack {
//                Spacer()
//                Button(action: {
//                    showingMapView = true
//                }) {
//                    Image("mapmonster")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 100, height: 100)
//                        .padding(15)
////                        .background(Color.white.opacity(0.7))
////                        .clipShape(Circle())
//                        .shadow(radius: 5)
//                }
//                .sheet(isPresented: $showingMapView) {
//                    MapViewWithUserLocation(locationManager: LocationManager(), isPresented: $showingMapView)
//                }
//                .padding(.trailing, 15)
//                .padding(.bottom, 15)
//            }
//        }
//    }
//}
