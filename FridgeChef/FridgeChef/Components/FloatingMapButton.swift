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
                            value: isScaledUp
                        )
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Circle())
                        .onAppear {
                            isScaledUp = true
                        }
                        .onDisappear {
                            isScaledUp = false
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
        StatefulPreviewWrapper(false) { isShowingMapView in
            FloatingMapButton(showingMapView: isShowingMapView)
        }
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
