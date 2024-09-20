//
//  MicButtonView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import SwiftUI

struct MicButtonView: View {
    @ObservedObject var recognitionService: RecognitionService

    var body: some View {
        Button(action: {
            if recognitionService.isRecording {
                recognitionService.stopRecording()
            } else {
                recognitionService.startRecording()
            }
        }) {
            Image(systemName: recognitionService.isRecording ? "mic.fill" : "mic")
                .font(.title)
                .foregroundColor(recognitionService.isRecording ? .red : .blue)
        }
    }
}

