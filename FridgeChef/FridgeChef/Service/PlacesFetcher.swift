//
//  PlacesFetcher.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/21.
//
import Foundation
import CoreLocation

struct Supermarket: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var address: String
    var coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude = "lat", longitude = "lng"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    static func == (lhs: Supermarket, rhs: Supermarket) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Supermarket {
    
    init(id: UUID, name: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
    }
}

struct PlacesResponse: Decodable {
    let results: [PlaceResult]
}

struct PlaceResult: Decodable {
    let name: String
    let vicinity: String
    let geometry: Geometry
}

struct Geometry: Decodable {
    let location: Location
}

struct Location: Decodable {
    let lat: Double
    let lng: Double
}

class PlacesFetcher: ObservableObject {
    @Published var supermarkets = [Supermarket]()
    private let savedSupermarketsKey = "savedSupermarkets"
    private let apiKey = "AIzaSyBb_LtEBzE0y2mATvrQ3sZnaWnieTHf6_E"//TODO Demo 記得改乘旁邊的 AIzaSyBb_LtEBzE0y2mATvrQ3sZnaWnieTHf6_E

    private let lastFetchedLatitudeKey = "lastFetchedLatitude"
    private let lastFetchedLongitudeKey = "lastFetchedLongitude"
    private let cacheTimeStampKey = "cacheTimeStamp"
    private var lastFetchedLocation: CLLocation?
    private var cacheDuration: TimeInterval = 60 * 60 // 1小時的緩存時間
    private var cacheTimeStamp: Date?
    var isDataLoadedFromStorage = false

    // 距離閾值 (500 公尺)
    private let fetchThresholdDistance: CLLocationDistance = 500

    // 儲存超市資料到本地
    func saveSupermarkets() {
        if let encodedData = try? JSONEncoder().encode(supermarkets) {
            UserDefaults.standard.set(encodedData, forKey: savedSupermarketsKey)
            print("Supermarkets saved to local storage.")
        }
    }

    // 從本地讀取已保存的超市資料
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

    // 保存緩存資料
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

    // 載入緩存資料
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

        if let lastLocation = lastFetchedLocation {
            print("Last fetched location: \(lastLocation.coordinate.latitude), \(lastLocation.coordinate.longitude)")
        } else {
            print("Last fetched location is nil, this should be the first API request.")
        }

        if let cacheTimeStamp = cacheTimeStamp {
            print("Cache timestamp: \(cacheTimeStamp)")
        } else {
            print("Cache timestamp is nil, should fetch new data.")
        }

        print("Current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")

        if let lastLocation = lastFetchedLocation {
            let distance = currentLocation.distance(from: lastLocation)
            print("Distance from last fetched location: \(distance) meters")
        }

        // **修改這裡，加入 supermarkets.isEmpty 的檢查**
               let shouldFetchNewData = supermarkets.isEmpty ||
                                        (lastFetchedLocation == nil) ||
                                        (currentLocation.distance(from: lastFetchedLocation ?? currentLocation) >= fetchThresholdDistance) ||
                                        (cacheTimeStamp == nil) ||
                                        (Date().timeIntervalSince(cacheTimeStamp!) >= cacheDuration)

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
                        // 更新 lastFetchedLocation 和 cacheTimeStamp，並保存緩存資料
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
