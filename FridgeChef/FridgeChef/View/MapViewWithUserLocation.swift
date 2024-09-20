//
//  MapViewWithUserLocation.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/20.
//

import SwiftUI
import MapKit

struct MapViewWithUserLocation: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var isPresented: Bool
    @State private var trackingMode: MapUserTrackingMode = .follow // 使用追踪模式的绑定属性
    
    var body: some View {
        if let userLocation = locationManager.lastKnownLocation {
            // 显示用户的当前位置并跟踪用户
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )), showsUserLocation: true, userTrackingMode: $trackingMode) // 使用 $trackingMode 绑定来跟踪用户
            .edgesIgnoringSafeArea(.all)
        } else {
            // 提示用户授予定位权限
            Text("定位中...")
                .onAppear {
                    locationManager.requestPermission() // 请求定位权限
                }
                .alert(isPresented: $locationManager.showAlert) {
                    Alert(
                        title: Text("需要定位權限"),
                        message: Text("請在設置中允許訪問位置信息"),
                        primaryButton: .default(Text("打開設置"), action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }),
                        secondaryButton: .cancel()
                    )
                }
        }
        // 添加一个关闭按钮
        Button(action: {
            isPresented = false // 设置为 false 来关闭 sheet
        }) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .padding()
                .background(Color.white.opacity(0.7))
                .clipShape(Circle())
                .shadow(radius: 5)
        }
        .padding()
    }
}
