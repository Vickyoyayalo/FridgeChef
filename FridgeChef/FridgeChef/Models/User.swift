//
//  User.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String? // Firestore的文件IDb
    var avatar: String
    var name: String
    var email: String
    var password: String
    var category: [String] // 使用類別的Array，如“套餐”或“中式”等

    // Firestore解碼所需的init
    init(id: String? = nil, avatar: String, name: String, email: String, password: String, category: [String]) {
        self.id = id
        self.avatar = avatar
        self.name = name
        self.email = email
        self.password = password
        self.category = category
    }
}

