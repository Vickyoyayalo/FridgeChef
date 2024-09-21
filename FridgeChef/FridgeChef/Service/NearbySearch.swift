//
//  NearbySearch.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/21.
//

import Foundation
import CoreLocation

struct Supermarket: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D

    // Equatable 协议实现，用于比较两个 `Supermarket` 实例是否相等
    static func == (lhs: Supermarket, rhs: Supermarket) -> Bool {
        return lhs.id == rhs.id
    }
}

class PlacesFetcher: ObservableObject {
    @Published var supermarkets = [Supermarket]()
    private let apiKey = "AIzaSyBb_LtEBzE0y2mATvrQ3sZnaWnieTHf6_E"
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate.latitude),\(coordinate.longitude)&radius=1000&type=supermarket&key=\(apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Failed to fetch places: \(error.localizedDescription)")
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    print("No data returned")
                }
                return
            }
            if let response = try? JSONDecoder().decode(PlacesResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.supermarkets = response.results.map {
                        Supermarket(name: $0.name, coordinate: CLLocationCoordinate2D(latitude: $0.geometry.location.lat, longitude: $0.geometry.location.lng))
                    }
                    print("Found places: \(self.supermarkets.count)")
                }
            } else {
                DispatchQueue.main.async {
                    print("Failed to decode response")
                }
            }
        }.resume()
    }
}

// Data structures for decoding JSON response
struct PlacesResponse: Codable {
    let results: [Place]
}

struct Place: Codable {
    let name: String
    let geometry: Geometry
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}
