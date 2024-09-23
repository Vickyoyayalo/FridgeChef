//
//  PlacesFetcher.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/21.
//
import Foundation
import CoreLocation

struct Supermarket: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var address: String
    var coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude = "lat", longitude = "lng"
    }
    // 自定义解码以支持 CLLocationCoordinate2D
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // 自定义编码
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
    // 新增一個普通的初始化方法來避免和 Codable 的 init(from:) 混淆
    init(id: UUID, name: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
    }
}

// 結構用來解碼 Places API 的回應
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
    private let apiKey = "AIzaSyBb_LtEBzE0y2mATvrQ3sZnaWnieTHf6_E"
    
    // 儲存上次 API 請求的位置和超市數據
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
    
    // 用來檢查和載入本地超市數據或從API獲取
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {
        // 加载上次缓存的超市数据（如果有）
        loadSavedSupermarkets()
        
        let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // 检查是否需要发起新的 API 请求
        if let lastLocation = lastFetchedLocation,
           currentLocation.distance(from: lastLocation) >= fetchThresholdDistance ||
            cacheTimeStamp == nil || Date().timeIntervalSince(cacheTimeStamp!) >= cacheDuration {
            
            print("Fetching new data from API...") // 这里添加日志语句
            
            lastFetchedLocation = currentLocation
            cacheTimeStamp = Date()
            
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
                        
                        // 只有当数据真的变化时才更新 @Published 的超市数组
                        if newSupermarkets != self.supermarkets {
                            self.supermarkets = newSupermarkets
                            self.saveSupermarkets()  // 保存新的超市数据到本地
                            print("Found places: \(self.supermarkets.count)")
                        } else {
                            print("Supermarkets data unchanged, no need to update.")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Failed to decode response: \(error)")
                    }
                }
            }.resume()
        } else {
            print("Using cached supermarkets data.") // 可以再次确认使用缓存数据
        }
    }
}

