//
//  String.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/2.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = self.first else { return self }
        return String(first).uppercased() + self.dropFirst()
    }
}
