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
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingMapView = true
                }) {
                    Image(systemName: "location.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(15)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                        .shadow(radius: 5)
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
