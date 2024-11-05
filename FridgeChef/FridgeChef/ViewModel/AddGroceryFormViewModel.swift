//
//  AddGroceryFormViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import Foundation
import SwiftUI
import Combine

class AddGroceryFormViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var type: String = ""
    @Published var location: String = ""
    @Published var phone: String = ""
    @Published var description: String = ""
    @Published var image: String?
    
    init(recommendRecipe: RecommendRecipe? = nil) {
        if let recipe = recommendRecipe {
            self.name = recipe.name
            self.type = recipe.type
            self.location = recipe.location
            self.phone = recipe.phone
            self.description = recipe.description
            self.image = recipe.image
        }
    }
}

