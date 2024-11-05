//
//  FoodItem.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//
import SwiftUI

struct FoodItem: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var quantity: Double
    var unit: String
    var status: Status
    var daysRemaining: Int
    var expirationDate: Date?
    var imageURL: String?
    
    var uiImage: UIImage? {
        get {
            guard let imageURL = imageURL else { return nil }
            if let url = URL(string: imageURL), let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
            return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, status, daysRemaining, expirationDate, imageURL
    }
}

enum Status: String, Codable {
    case toBuy = "toBuy"
    case fridge = "Fridge"
    case freezer = "Freezer"
}

extension FoodItem {
    var daysRemainingText: String {
        switch status {
        case .toBuy:
            if let expirationDate = expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                let dateString = formatter.string(from: expirationDate)
                return "To Buy by \(dateString)"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                let today = Date()
                let dateString = formatter.string(from: today)
                return "To Buy \(dateString)"
            }
        case .fridge, .freezer:
            if daysRemaining > 5 {
                return "Can keep \(daysRemaining) days👨🏻‍🌾"
            } else if daysRemaining > 0 {
                return "\(daysRemaining) day\(daysRemaining > 1 ? "s" : "") left👀"
            } else if daysRemaining == 0 {
                return "It's TODAY🌶️"
            } else {
                return "Expired \(abs(daysRemaining)) days‼️"
            }
        }
    }
    
    var daysRemainingColor: Color {
        switch status {
        case .toBuy:
            if let expirationDate = expirationDate {
                if expirationDate < Date() {
                    return .red
                } else {
                    return .blue
                }
            } else {
                return .blue
            }
        case .fridge, .freezer:
            if daysRemaining > 5 {
                return .gray
            } else if daysRemaining > 2 {
                return .purple
            } else if daysRemaining > 0 {
                return .blue
            } else if daysRemaining == 0 {
                return .orange
            } else {
                return .red
            }
        }
    }
    
    var daysRemainingFontWeight: Font.Weight {
        switch status {
        case .toBuy:
            return .bold
        case .fridge, .freezer:
            return daysRemaining <= 5 ? .bold : .regular
        }
    }
}

import SDWebImageSwiftUI

struct FoodItemRow: View {
    var item: FoodItem
    var moveToGrocery: ((FoodItem) -> Void)?
    var moveToFridge: ((FoodItem) -> Void)?
    var moveToFreezer: ((FoodItem) -> Void)?
    var onTap: ((FoodItem) -> Void)?
    
    var body: some View {
        HStack {
            if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
                WebImage(url: imageURL)
                    .onSuccess { image, data, cacheType in
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(
                        Image("RecipeFood")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .opacity(0.3)
                    )
                
            } else {
                Image("RecipeFood")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.custom("ArialRoundedMTBold", size: 16))
                Text("\(item.quantity, specifier: "%.1f") \(item.unit)")
                    .font(.custom("ArialRoundedMTBold", size: 14))
                    .foregroundColor(.gray)
                Text(item.daysRemainingText)
                    .font(.custom("ArialRoundedMTBold", size: 14))
                    .foregroundColor(item.daysRemainingColor)
                    .fontWeight(item.daysRemainingFontWeight)
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                
                if let moveToGrocery = moveToGrocery {
                    Button(action: {
                        moveToGrocery(item)
                    }) {
                        Image(systemName: "cart.fill")
                            .foregroundColor(.green)
                    }
                }
                
                if let moveToFridge = moveToFridge {
                    Button(action: {
                        moveToFridge(item)
                    }) {
                        Image(systemName: "refrigerator.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                if let moveToFreezer = moveToFreezer {
                    Button(action: {
                        moveToFreezer(item)
                    }, label: {
                        Image(systemName: "snowflake")
                            .foregroundColor(.blue)
                    })
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?(item)
        }
    }
}
