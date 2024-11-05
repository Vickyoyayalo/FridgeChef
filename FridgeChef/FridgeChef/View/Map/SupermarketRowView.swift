//
//  SupermarketRow.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import SwiftUI
import MapKit
import Foundation

struct SupermarketRowView: View {
    let supermarket: Supermarket
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(supermarket.name)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
            Text("\(supermarket.address) - \(distanceToUser() ?? 0, specifier: "%.2f") km")
                .font(.custom("ArialRoundedMTBold", size: 13))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
        }
        .padding(.vertical)
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.9)))
    }
    
    private func distanceToUser() -> Double? {
        guard let userLocation = userLocation else { return nil }
        let supermarketLocation = CLLocation(latitude: supermarket.coordinate.latitude, longitude: supermarket.coordinate.longitude)
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        return supermarketLocation.distance(from: userCLLocation) / 1000
    }
}

