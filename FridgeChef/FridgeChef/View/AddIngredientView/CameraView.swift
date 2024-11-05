//
//  CameraView.swift
//  ScanAndRecognizeText
//
//  Created by Vickyhereiam on 2024/9/11.
//
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    
    var onImagePicked: (UIImage) -> Void
    var onCancel: () -> Void
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
            picker.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(
            onImagePicked: { _ in },
            onCancel: {}
        )
    }
}
