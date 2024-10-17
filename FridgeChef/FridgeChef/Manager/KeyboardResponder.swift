//
//  KeyboardResponder.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/24.
//

import Combine
import SwiftUI

class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] height in
                self?.currentHeight = height
            })
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] height in
                self?.currentHeight = 0
            })
            .store(in: &cancellables)
    }
}


