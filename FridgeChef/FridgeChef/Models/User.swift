//
//  User.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String? 
    var avatar: String?
    var name: String
    var email: String
    var password: String

    init(id: String? = nil, avatar: String?, name: String, email: String, password: String) {
        self.id = id
        self.avatar = avatar
        self.name = name
        self.email = email
        self.password = password
        
    }
}
