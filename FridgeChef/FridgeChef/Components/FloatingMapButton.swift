//
//  FloatingMapButton.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/3.
//

import SwiftUI

struct FloatingMapButton: View {
    @Binding var showingMapView: Bool
    @State private var isScaledUp = false
    @State private var showingAlert = false
    private let alertService = AlertService()
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    if let apiKey = APIKeyManager.shared.getAPIKey(forKey: "SupermarketAPI_Key") {
                        let placesFetcher = PlacesFetcher(apiKey: apiKey)
                        _ = LocationManager(placesFetcher: placesFetcher)
                        showingMapView = true
                    } else {
                        showingAlert = true
                    }
                }, label: {
                    Image("mapmonster")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .scaleEffect(isScaledUp ? 1.0 : 0.8)
                        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isScaledUp)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Circle())
                        .onAppear {
                            isScaledUp = true
                        }
                        .onDisappear {
                            isScaledUp = false
                        }
                })
                .sheet(isPresented: $showingMapView, content: {
                    let placesFetcher = PlacesFetcher(apiKey: APIKeyManager.shared.getAPIKey(forKey: "SupermarketAPI_Key") ?? "")
                    let locationManager = LocationManager(placesFetcher: placesFetcher)
                    MapView(locationManager: locationManager, isPresented: $showingMapView)
                })
                .alert(isPresented: $showingAlert, content: {
                    alertService.showAlert(
                        title: "API Key Missing",
                        message: "API Key is missing. Please check your configuration."
                    )
                })
                .padding(.trailing, 15)
                .padding(.bottom, 15)
                .shadow(radius: 10)
            }
        }
    }
}

struct FloatingMapButton_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false, content: { isShowingMapView in
            FloatingMapButton(showingMapView: isShowingMapView)
        })
    }
}

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
