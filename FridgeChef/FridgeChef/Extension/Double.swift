//
//  Double.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/3.
//

import Foundation

extension Double {
    /// 將 Double 四捨五入到指定的小數位數
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
