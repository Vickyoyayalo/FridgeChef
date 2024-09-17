//
//  AlertService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/17.
//

import SwiftUI

class AlertService {
    func showAlert(title: String, message: String) -> Alert {
        return Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("確定")))
    }
}
