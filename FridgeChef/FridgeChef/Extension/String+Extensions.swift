//
//  String+Extensions.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/2.
//

import Foundation

extension String {
    /// 將字串的第一個字母大寫，其餘保持不變
    func capitalizingFirstLetter() -> String {
        guard let first = self.first else { return self }
        return String(first).uppercased() + self.dropFirst()
    }
}
