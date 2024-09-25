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
        // Listen for the keyboard will show notification
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .receive(on: DispatchQueue.main)  // Ensure update happens on the main thread
            .sink(receiveValue: { [weak self] height in
                self?.currentHeight = height
            })
            .store(in: &cancellables)

        // Listen for the keyboard will hide notification
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .receive(on: DispatchQueue.main)  // Ensure update happens on the main thread
            .sink(receiveValue: { [weak self] height in
                self?.currentHeight = 0
            })
            .store(in: &cancellables)
    }
}


