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
                        .frame(width: 80, height: 80)
                        .scaleEffect(isScaledUp ? 1.0 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: isScaledUp // 添加 value 確保動畫更新
                        )
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Circle())
                        .onAppear {
                            isScaledUp = true // 確保動畫從頭開始
                        }
                        .onDisappear {
                            isScaledUp = false // 避免動畫狀態失效
                        }
                }
                .sheet(isPresented: $showingMapView) {
                    MapViewWithUserLocation(locationManager: LocationManager(), isPresented: $showingMapView)
                }
                .padding(.trailing, 15)
                .padding(.bottom, 15)
                .shadow(radius: 10)
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
