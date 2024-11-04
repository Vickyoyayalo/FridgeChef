//
//  CacheResponse.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct CachedResponse: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let message: String
    let response: String
    let timestamp: Date
}
