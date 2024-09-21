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
    @State private var selectedSupermarket: Supermarket?
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            CustomMapView(region: $locationManager.region, selectedSupermarket: $selectedSupermarket, locationManager: locationManager, supermarkets: locationManager.placesFetcher.supermarkets.filter { supermarket in
                searchText.isEmpty || supermarket.name.localizedCaseInsensitiveContains(searchText)
            })
            
            .onChange(of: selectedSupermarket) { _ in
                // 防止地圖在選擇標記後重新聚焦到用戶位置
                locationManager.isUserInteracting = true
            }
            .gesture(DragGesture().onChanged { _ in
                locationManager.isUserInteracting = true
            }.onEnded { _ in
                locationManager.isUserInteracting = false
            })
            
            VStack {
                HStack {
                    TextField("Search for supermarkets...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Search") {
                        if let coordinate = locationManager.lastKnownLocation?.coordinate {
                            locationManager.placesFetcher.fetchNearbyPlaces(coordinate: coordinate)
                        }
                    }
                }
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding()
                .background(Color.clear)
            }
            .edgesIgnoringSafeArea(.all)
        }
        // 顯示選中的超市地址和導航按鈕
        .alert(item: $selectedSupermarket) { supermarket in
            Alert(
                title: Text(supermarket.name),
                message: Text(supermarket.address),
                primaryButton: .default(Text("導航"), action: {
                    openMapsAppWithDirections(to: supermarket.coordinate, destinationName: supermarket.name)
                }),
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
    
    // 打開 Apple Maps 進行導航
    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destinationName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

//import SwiftUI
//import MapKit
//
//struct MapViewWithUserLocation: View {
//    @ObservedObject var locationManager: LocationManager
//    @Binding var isPresented: Bool
//    @State private var selectedSupermarket: Supermarket?
//    @State private var searchText: String = ""
//    
//    var body: some View {
//        ZStack {
//            CustomMapView(region: $locationManager.region, selectedSupermarket: $selectedSupermarket, searchText: $searchText, locationManager: locationManager, supermarkets: locationManager.placesFetcher.supermarkets)
//
//                .onChange(of: selectedSupermarket) { _ in
//                    // 防止地圖在選擇標記後重新聚焦到用戶位置
//                    locationManager.isUserInteracting = true
//                }
//                .gesture(DragGesture().onChanged { _ in
//                    locationManager.isUserInteracting = true
//                }.onEnded { _ in
//                    locationManager.isUserInteracting = false
//            })
//            VStack {
//                HStack {
//                    TextField("Search for supermarkets...", text: $searchText)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//                    Button("Search") {
//                        if let coordinate = locationManager.lastKnownLocation?.coordinate {
//                            locationManager.placesFetcher.fetchNearbyPlaces(coordinate: coordinate)
//                        }
//                    }
//                }
//                Spacer()
//                Button(action: {
//                    isPresented = false
//                }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .resizable()
//                        .frame(width: 40, height: 40)
//                        .padding()
//                        .background(Color.white.opacity(0.8))
//                        .clipShape(Circle())
//                        .shadow(radius: 5)
//                }
//                .padding()
//                .background(Color.clear)
//            }
//            .edgesIgnoringSafeArea(.all)
//        }
//        .alert(item: $selectedSupermarket) { supermarket in
//            Alert(title: Text(supermarket.name), message: Text("Coordinates: \(supermarket.coordinate.latitude), \(supermarket.coordinate.longitude)"), dismissButton: .default(Text("OK")))
//        }
//    }
//}
