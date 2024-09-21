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
            CustomMapView(region: $locationManager.region, selectedSupermarket: $selectedSupermarket, searchText: $searchText, locationManager: locationManager, supermarkets: locationManager.placesFetcher.supermarkets)
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
        .alert(item: $selectedSupermarket) { supermarket in
            Alert(title: Text(supermarket.name), message: Text("Coordinates: \(supermarket.coordinate.latitude), \(supermarket.coordinate.longitude)"), dismissButton: .default(Text("OK")))
        }
    }
}


//MARK: GOOD
//import SwiftUI
//import MapKit
//
//struct MapViewWithUserLocation: View {
//    @ObservedObject var locationManager: LocationManager
//    @Binding var isPresented: Bool
//
//    var body: some View {
//        ZStack {
//            Map(coordinateRegion: $locationManager.region, interactionModes: .all, showsUserLocation: true, annotationItems: locationManager.placesFetcher.supermarkets) { supermarket in
//                MapMarker(coordinate: supermarket.coordinate, tint: .red)
//            }
//            .onAppear {
//                if let coordinate = locationManager.lastKnownLocation?.coordinate {
//                    locationManager.updateRegion(coordinate: coordinate, zoomIn: true)
//                }
//            }
//            .gesture(DragGesture().onChanged { _ in
//                locationManager.isUserInteracting = true
//            }.onEnded { _ in
//                locationManager.isUserInteracting = false
//            })
//
//            VStack {
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
//        .alert(isPresented: $locationManager.showAlert) {
//            Alert(title: Text("需要定位权限"), message: Text("请在设置中允许访问位置信息"), dismissButton: .default(Text("好")))
//        }
//    }
//}
//
