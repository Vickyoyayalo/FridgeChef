//
//  MapView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI
import MapKit

struct MapView: View {
    var location: String = ""
    var interactionMode: MapInteractionModes = .all
    
    @State private var position: MapCameraPosition = .automatic
    @State private var markerLocation = CLLocation()
    
    var body: some View {
        
        Map(position: $position, interactionModes: interactionMode) {
            Marker("", coordinate: markerLocation.coordinate)
                .tint(.red)
        }
        .task {
            convertAddress(location: location)
        }
        
    }
    
    private func convertAddress(location: String) {
        
        print("Calling convert address...")
        
        // Get location
        let geoCoder = CLGeocoder()

        geoCoder.geocodeAddressString(location, completionHandler: { placemarks, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let placemarks = placemarks,
                  let location = placemarks[0].location else {
                return
            }
            
            print(location.coordinate)
            
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015))
            
            self.position = .region(region)
            self.markerLocation = location
        })
    }
}

#Preview {
    MapView(location: "54 Frith Street London W1D 4SL United Kingdom")
}

//import SwiftUI
//import MapKit
//import CoreLocation
//
//struct MapView: View {
//    var location: String = ""
//    var interactionMode: MapInteractionModes = .all
//    @State var isUserLocation: Bool
//    @State private var position: MapCameraPosition = .automatic
//    @State private var markerLocation = CLLocation()
//    @StateObject private var locationManager = LocationManager() // 管理位置信息的对象
//
//    var body: some View {
//        Map(position: $position, interactionModes: interactionMode) {
//            Marker("", coordinate: markerLocation.coordinate)
//                .tint(.red)
//        }
//        .task {
//            await handleLocationTask()
//        }
//    }
//
//    // 处理位置更新的任务
//    private func handleLocationTask() async {
//        if isUserLocation {
//            getUserLocation()
//        } else {
//            convertAddress(location: location)
//        }
//    }
//
//    // 获取用户位置
//    private func getUserLocation() {
//        if let userLocation = locationManager.lastKnownLocation {
//            DispatchQueue.main.async {
//                self.position = .region(MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
//                self.markerLocation = userLocation
//            }
//        } else {
//            print("Unable to fetch user location.")
//        }
//    }
//
//    // 地址转换为坐标
//    private func convertAddress(location: String) {
//        let geoCoder = CLGeocoder()
//        geoCoder.geocodeAddressString(location) { placemarks, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Geocoding failed with error: \(error.localizedDescription)")
//                    return
//                }
//                guard let location = placemarks?.first?.location else {
//                    print("No valid location found.")
//                    return
//                }
//                self.position = .region(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)))
//                self.markerLocation = location
//            }
//        }
//    }
//}
//
//
//// 正确的预览部分
//struct MapView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapView(location: "台中市潭子區弘勇街323號", isUserLocation: false)
//    }
//}
