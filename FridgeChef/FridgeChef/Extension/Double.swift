//
//  Double.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/3.
//

import Foundation

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
