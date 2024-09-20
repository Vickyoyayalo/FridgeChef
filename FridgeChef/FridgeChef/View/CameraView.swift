//
//  CameraView.swift
//  ScanAndRecognizeText
//
//  Created by Vickyhereiam on 2024/9/11.
//

import SwiftUI
import UIKit

// 這個結構將 UIImagePickerController 封裝為 SwiftUI 可用的視圖
struct CameraView: UIViewControllerRepresentable {
    
    var onImagePicked: (UIImage) -> Void
    var onCancel: () -> Void
    
    // Coordinator 來處理相機的事件
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        // 當用戶拍照完成後，這個方法會被觸發
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image) // 將圖片返回給 SwiftUI 視圖
            }
            picker.dismiss(animated: true)
        }
        
        // 當用戶取消拍照時，這個方法會被觸發
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel() // 取消操作
            picker.dismiss(animated: true)
        }
    }
    
    // 創建 UIImagePickerController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera // 使用相機作為圖片源
        picker.allowsEditing = false
        // 禁用編輯
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    // 建立 Coordinator，來處理 UIImagePickerController 的事件
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            MLIngredientView()
//            MLIngredientView(viewModel: MLIngredientViewModel())
        } else {
            // Fallback on earlier versions
        }
    }
}

