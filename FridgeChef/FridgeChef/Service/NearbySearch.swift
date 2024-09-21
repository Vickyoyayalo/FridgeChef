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
    let address: String
    let coordinate: CLLocationCoordinate2D

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
            if let decodedResponse = try? JSONDecoder().decode(PlacesResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.supermarkets = decodedResponse.results.map { result in
                        Supermarket(name: result.name, address: result.vicinity, coordinate: CLLocationCoordinate2D(latitude: result.geometry.location.lat, longitude: result.geometry.location.lng))
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
    let vicinity: String  // Assuming 'vicinity' is the key for the address in the API response
    let geometry: Geometry
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}
