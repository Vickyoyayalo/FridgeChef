//
//  FirebaseManager.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let firestore: Firestore
    let storage: Storage
    
    private init() {
        FirebaseApp.configure() // 初始化 Firebase
        
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        self.storage = Storage.storage()
    }
}
