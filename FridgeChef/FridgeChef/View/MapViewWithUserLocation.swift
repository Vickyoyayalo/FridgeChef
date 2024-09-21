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
    @State private var searchResults: [Supermarket] = []
    @State private var showingNavigationAlert: Bool = false
    
    var body: some View {
        ZStack {
            map
            VStack {
                searchField
                if !searchResults.isEmpty {
                    listResults
                }
                Spacer()
                dismissButton
            }
        }
        .alert(isPresented: $showingNavigationAlert) { // Alert now depends on showingNavigationAlert
            Alert(
                title: Text("Navigate to \(selectedSupermarket?.name ?? "the selected location")?"),
                message: Text("Do you want to navigate to \(selectedSupermarket?.name ?? "this supermarket") located at \(selectedSupermarket?.address ?? "")?"),
                primaryButton: .default(Text("Let's GO 🛒"), action: {
                    if let supermarket = selectedSupermarket {
                        openMapsAppWithDirections(to: supermarket.coordinate, destinationName: supermarket.name)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }
    
    private var searchField: some View {
        HStack(alignment: .center) {
            TextField("搜尋附近超市..🏃🏻‍♀️‍➡️.", text: $searchText)
                .padding(.leading, 10)
                .padding(.vertical, 10) // Vertical padding adjusted for alignment
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
                .overlay(
                    HStack {
                        Spacer()
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .onChange(of: searchText, perform: { _ in
                    searchSupermarkets()
                })
            
            Button(action: {
                searchSupermarkets()
            }) {
                Text("Search🔍")
                    .bold()
                    .foregroundColor(.white)
                    .padding(.vertical, 10)  // Matched vertical padding to TextField
                    .padding(.horizontal, 20)
                    .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
        }
        .padding(.horizontal) // Add padding around the entire HStack
        .padding(.top, 10)    // Add top padding for alignment
    }
    var navigationButton: some View {
        Button(action: {
            if let supermarket = searchResults.first {
                selectedSupermarket = supermarket
                navigateTo(supermarket: supermarket)
            }
        }) {
            Text("Navigate to First Result 🧭")
                .bold()
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color.orange)
                .cornerRadius(10)
                .shadow(radius: 3)
        }
    }
    
    private func navigateTo(supermarket: Supermarket) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: supermarket.coordinate))
        destination.name = supermarket.name
        destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private var map: some View {
        CustomMapView(region: $locationManager.region, selectedSupermarket: $selectedSupermarket, locationManager: locationManager, supermarkets: locationManager.placesFetcher.supermarkets.filter { supermarket in
            searchText.isEmpty || supermarket.name.localizedCaseInsensitiveContains(searchText)
        })
        .edgesIgnoringSafeArea(.all)
        .onChange(of: selectedSupermarket) { _ in
            locationManager.isUserInteracting = true
        }
        .gesture(DragGesture().onChanged { _ in
            locationManager.isUserInteracting = true
        }.onEnded { _ in
            locationManager.isUserInteracting = false
        })
    }
    private var listResults: some View {
        List(searchResults, id: \.id) { supermarket in
            VStack(alignment: .leading) {
                Text(supermarket.name)
                    .fontWeight(.bold)
                Text("\(supermarket.address) - \(supermarket.distanceToUser(location: locationManager.lastKnownLocation?.coordinate) ?? 0, specifier: "%.2f") km")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical) // Add vertical padding to each cell
            .listRowBackground(Color.clear)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.9))) // Optional: if you want some opacity// Make row backgrounds clear
            .onTapGesture {
                self.selectedSupermarket = supermarket
                navigateTo(supermarket: supermarket)
                self.showingNavigationAlert = true
            }
        }
        .padding(.horizontal, 10) // Add horizontal padding around the list
        .listStyle(PlainListStyle()) // Use plain style to remove any inherent list styling
        .background(Color.clear) // Ensure the list’s background is clear
    }
    
    
    private var dismissButton: some View {
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
    }
    
    private func performSearch() {
            if let coordinate = locationManager.lastKnownLocation?.coordinate {
                locationManager.placesFetcher.fetchNearbyPlaces(coordinate: coordinate)
            }
            // Optionally, navigate to the first result after fetching
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // assuming delay for fetching
                if let firstResult = searchResults.first {
                    self.selectedSupermarket = firstResult
                    openMapsAppWithDirections(to: firstResult.coordinate, destinationName: firstResult.name)
                }
            }
        }
    
    private func searchSupermarkets() {
            searchResults = locationManager.placesFetcher.supermarkets.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
            if let firstResult = searchResults.first {
                selectedSupermarket = firstResult
//                showingNavigationAlert = true // Set to true to show the alert
            }
        }

    
    private func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destinationName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

extension Supermarket {
    func distanceToUser(location: CLLocationCoordinate2D?) -> Double? {
        guard let userLocation = location else { return nil }
        let supermarketLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        return supermarketLocation.distance(from: userCLLocation) / 1000 // Convert to kilometers
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
//            CustomMapView(region: $locationManager.region, selectedSupermarket: $selectedSupermarket, locationManager: locationManager, supermarkets: locationManager.placesFetcher.supermarkets.filter { supermarket in
//                searchText.isEmpty || supermarket.name.localizedCaseInsensitiveContains(searchText)
//            })
//            .edgesIgnoringSafeArea(.all)
//            .onChange(of: selectedSupermarket) { _ in
//                // 防止地圖在選擇標記後重新聚焦到用戶位置
//                locationManager.isUserInteracting = true
//            }
//            .gesture(DragGesture().onChanged { _ in
//                locationManager.isUserInteracting = true
//            }.onEnded { _ in
//                locationManager.isUserInteracting = false
//            })
//
//            VStack {
//                HStack {
//                    TextField("搜尋附近超市..🏃🏻‍♀️‍➡️.", text: $searchText)
//                        .padding(8)
//                        .background(Color.white)
//                        .cornerRadius(10)
//                        .shadow(radius: 3)
//                        .padding(.horizontal)
//                    Button(action: {
//                        if let coordinate = locationManager.lastKnownLocation?.coordinate {
//                            locationManager.placesFetcher.fetchNearbyPlaces(coordinate: coordinate)
//                        }
//                    }) {
//                        Text("Search🔍")
//                            .bold()
//                            .foregroundColor(.white)
//                            .padding(.vertical, 10)
//                            .padding(.horizontal, 20)
//                            .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange)) // 使用自定 UIColor，如果找不到則回退到藍色
//                            .cornerRadius(10)
//                            .shadow(radius: 3)
//                    }
//                    .padding(.trailing)
//                }
//                .padding(.top, 20) // 為了防止與頂部狀態欄重疊
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
//        // 顯示選中的超市地址和導航按鈕
//        .alert(item: $selectedSupermarket) { supermarket in
//            Alert(
//                title: Text(supermarket.name),
//                message: Text(supermarket.address),
//                primaryButton: .default(Text("導航"), action: {
//                    openMapsAppWithDirections(to: supermarket.coordinate, destinationName: supermarket.name)
//                }),
//                sebook.closedcondaryButton: .cancel(Text("取消"))
//            )
//        }
//    }
//
//    // 打開 Apple Maps 進行導航
//    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName: String) {
//        let placemark = MKPlacemark(coordinate: coordinate)
//        let mapItem = MKMapItem(placemark: placemark)
//        mapItem.name = destinationName
//        mapItem.openInMaps(launchOptions: [
//            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
//        ])
//    }
//}
