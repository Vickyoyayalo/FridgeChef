//
//  RecipeSearchService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/28.
//

import Foundation

// MARK: - APIErrorResponse

struct APIErrorResponse: Codable {
    let code: Int?
    let message: String?
    let status: String?
}

// MARK: - RecipeSearchService

class RecipeSearchService {
    private let baseURL = "https://api.spoonacular.com/recipes"
    
    private var apiKey: String? {
        return APIKeyManager.shared.getAPIKey(forKey: "SpoonacularAPI_Key")
    }
    
    private func fetchData<T: Codable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Data Task Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }
            guard let data = data else {
                let noDataError = NSError(domain: "No Data", code: 0, userInfo: nil)
                DispatchQueue.main.async {
                    print("Data Task Error: No Data")
                    completion(.failure(noDataError))
                }
                return
            }
            
            if let rawString = String(data: data, encoding: .utf8) {
                print("Raw Response Data: \(rawString)")
            }
            
            DispatchQueue.main.async {
                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedResponse))
                } catch {
                    self.handleDecodingError(error, data: data, completion: completion)
                }
            }
        }.resume()
    }
    
    private func handleDecodingError<T>(_ error: Error, data: Data, completion: @escaping (Result<T, Error>) -> Void) {
        do {
            let apiError = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            let apiErrorMsg = NSError(domain: "API Error", code: apiError.code ?? 0, userInfo: [NSLocalizedDescriptionKey: apiError.message ?? "Unknown error"])
            print("API Error: \(apiError.message ?? "Unknown error")")
            completion(.failure(apiErrorMsg))
        } catch {
            print("Decoding Error: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func searchRecipes(query: String, maxFat: Int?, completion: @escaping (Result<RecipeSearchResponse, Error>) -> Void) {
        guard let apiKey = apiKey else {
            completion(.failure(NSError(domain: "API Key Missing", code: 401, userInfo: nil)))
            return
        }
        
        var components = URLComponents(string: "\(baseURL)/complexSearch")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "number", value: "10"),
            URLQueryItem(name: "addRecipeInformation", value: "true")
        ]
        
        if let maxFat = maxFat {
            components.queryItems?.append(URLQueryItem(name: "maxFat", value: "\(maxFat)"))
        }
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        print("Fetching URL: \(url.absoluteString)")
        fetchData(url: url, completion: completion)
    }
    
    func getRecipeInformation(recipeId: Int, completion: @escaping (Result<RecipeDetails, Error>) -> Void) {
        guard let apiKey = apiKey else {
            completion(.failure(NSError(domain: "API Key Missing", code: 401, userInfo: nil)))
            return
        }
        
        let urlString = "\(baseURL)/\(recipeId)/information?apiKey=\(apiKey)&includeNutrition=false"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        print("Fetching URL: \(url.absoluteString)")
        fetchData(url: url, completion: completion)
    }
}
