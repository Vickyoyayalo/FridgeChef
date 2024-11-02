//
//  PlacesFetcher.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/21.
//

import Foundation
import CoreLocation
import Combine

class PlacesFetcher: ObservableObject {
    @Published var supermarkets = [Supermarket]()
    private let savedSupermarketsKey = "savedSupermarkets"
    private let apiKey: String
    private let lastFetchedLatitudeKey = "lastFetchedLatitude"
    private let lastFetchedLongitudeKey = "lastFetchedLongitude"
    private let cacheTimeStampKey = "cacheTimeStamp"
    private var lastFetchedLocation: CLLocation?
    private var cacheDuration: TimeInterval = 60 * 60
    private var cacheTimeStamp: Date?
    private let fetchThresholdDistance: CLLocationDistance = 500
    var isDataLoadedFromStorage = false
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func saveSupermarkets() {
        if let encodedData = try? JSONEncoder().encode(supermarkets) {
            UserDefaults.standard.set(encodedData, forKey: savedSupermarketsKey)
            print("Supermarkets saved to local storage.")
        }
    }
    
    func loadSavedSupermarkets() {
        if !isDataLoadedFromStorage {
            if let savedData = UserDefaults.standard.data(forKey: savedSupermarketsKey),
               let decodedSupermarkets = try? JSONDecoder().decode([Supermarket].self, from: savedData) {
                supermarkets = decodedSupermarkets
                print("Loaded \(supermarkets.count) supermarkets from local storage.")
            }
            isDataLoadedFromStorage = true
        } else {
            print("Supermarkets data already loaded from local storage.")
        }
    }
    
    func saveCacheData() {
        if let lastLocation = lastFetchedLocation {
            UserDefaults.standard.set(lastLocation.coordinate.latitude, forKey: lastFetchedLatitudeKey)
            UserDefaults.standard.set(lastLocation.coordinate.longitude, forKey: lastFetchedLongitudeKey)
            print("Saved last fetched location: \(lastLocation.coordinate.latitude), \(lastLocation.coordinate.longitude)")
        }
        if let cacheTimeStamp = cacheTimeStamp {
            UserDefaults.standard.set(cacheTimeStamp, forKey: cacheTimeStampKey)
            print("Saved cache timestamp: \(cacheTimeStamp)")
        }
    }
    
    func loadCacheData() {
        let latitude = UserDefaults.standard.double(forKey: lastFetchedLatitudeKey)
        let longitude = UserDefaults.standard.double(forKey: lastFetchedLongitudeKey)
        if latitude != 0.0 && longitude != 0.0 {
            lastFetchedLocation = CLLocation(latitude: latitude, longitude: longitude)
            print("Loaded last fetched location: \(latitude), \(longitude)")
        } else {
            print("No last fetched location found in storage.")
        }
        
        if let timestamp = UserDefaults.standard.object(forKey: cacheTimeStampKey) as? Date {
            cacheTimeStamp = timestamp
            print("Loaded cache timestamp: \(cacheTimeStamp!)")
        } else {
            print("No cache timestamp found in storage.")
        }
    }
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        loadCacheData()
        loadSavedSupermarkets()
        
        let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let shouldFetchNewData = supermarkets.isEmpty ||
        lastFetchedLocation == nil ||
        cacheTimeStamp == nil ||
        currentLocation.distance(from: lastFetchedLocation ?? currentLocation) >= fetchThresholdDistance ||
        Date().timeIntervalSince(cacheTimeStamp!) >= cacheDuration
        
        if shouldFetchNewData {
            print("Fetching new data from API...")
            
            let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate.latitude),\(coordinate.longitude)&radius=5000&type=supermarket&key=\(apiKey)&language=zh-TW"
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
                do {
                    let decodedResponse = try JSONDecoder().decode(PlacesResponse.self, from: data)
                    DispatchQueue.main.async {
                        let newSupermarkets = decodedResponse.results.map { result in
                            Supermarket(
                                id: UUID(),
                                name: result.name,
                                address: result.vicinity,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: result.geometry.location.lat,
                                    longitude: result.geometry.location.lng
                                )
                            )
                        }
                        
                        if newSupermarkets != self.supermarkets {
                            self.supermarkets = newSupermarkets
                            self.saveSupermarkets()
                            print("Found places: \(self.supermarkets.count)")
                        } else {
                            print("Supermarkets data unchanged, no need to update.")
                        }
                        
                        self.lastFetchedLocation = currentLocation
                        self.cacheTimeStamp = Date()
                        self.saveCacheData()
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Failed to decode response: \(error)")
                    }
                }
            }.resume()
        } else {
            print("Using cached supermarkets data.")
        }
    }
}
