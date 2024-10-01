//
//  TranslationAPI.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/1.
//

import Foundation

func translate(text: String, from sourceLanguage: String = "zh", to targetLanguage: String = "en", completion: @escaping (String?) -> Void) {
    let apiKey = ""/*AIzaSyBb_LtEBzE0y2mATvrQ3sZnaWnieTHf6_E*/
    let urlStr = "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)"
    guard let url = URL(string: urlStr) else {
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let bodyParams = [
        "q": text,
        "source": sourceLanguage,
        "target": targetLanguage,
        "format": "text"
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: bodyParams, options: [])
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Translation error: \(error)")
            completion(nil)
            return
        }
        guard let data = data else {
            completion(nil)
            return
        }
        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let dict = json as? [String: Any],
           let dataDict = dict["data"] as? [String: Any],
           let translations = dataDict["translations"] as? [[String: Any]],
           let translation = translations.first?["translatedText"] as? String {
            completion(translation)
        } else {
            completion(nil)
        }
    }
    task.resume()
}
