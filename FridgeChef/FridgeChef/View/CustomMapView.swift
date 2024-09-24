//
//  CustomMapView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/21.

//MARK: 可行
import MapKit
import SwiftUI

struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var showingNavigationAlert: Bool
    @Binding var selectedSupermarket: Supermarket?
    var locationManager: LocationManager
    var supermarkets: [Supermarket]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if !locationManager.isUserInteracting {
            // 只有當區域實際改變時才設置
            if mapView.region.center.latitude != region.center.latitude ||
                mapView.region.center.longitude != region.center.longitude ||
                mapView.region.span.latitudeDelta != region.span.latitudeDelta ||
                mapView.region.span.longitudeDelta != region.span.longitudeDelta {
                mapView.setRegion(region, animated: true)
            }
        }
        let previouslySelectedID = context.coordinator.selectedSupermarketID
        updateAnnotations(mapView: mapView)
        
        // 重新選中標註
        if let selectedID = previouslySelectedID,
           let annotation = mapView.annotations.compactMap({ $0 as? CustomAnnotation }).first(where: { $0.supermarket.id == selectedID }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }

    
    private func updateAnnotations(mapView: MKMapView) {
        // 現有的 CustomAnnotation
        let existingAnnotations = mapView.annotations.compactMap { $0 as? CustomAnnotation }
        let existingSupermarketIDs = Set(existingAnnotations.map { $0.supermarket.id })
        let newSupermarketIDs = Set(supermarkets.map { $0.id })
        
        // 找出需要移除的超市
        let supermarketsToRemove = existingSupermarketIDs.subtracting(newSupermarketIDs)
        let annotationsToRemove = existingAnnotations.filter { supermarketsToRemove.contains($0.supermarket.id) }
        mapView.removeAnnotations(annotationsToRemove)
        
        // 找出需要添加的超市
        let supermarketsToAdd = newSupermarketIDs.subtracting(existingSupermarketIDs)
        let supermarketsToAddList = supermarkets.filter { supermarketsToAdd.contains($0.id) }
        for supermarket in supermarketsToAddList {
            let annotation = CustomAnnotation(supermarket: supermarket)
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        var selectedSupermarketID: UUID?
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? CustomAnnotation else { return nil }
            let identifier = "Supermarket"
            var view: MKMarkerAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = dequeuedView
                view.annotation = annotation
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                let rightButton = UIButton(type: .detailDisclosure)
                view.rightCalloutAccessoryView = rightButton
            }
            
            view.markerTintColor = .red
            return view
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            print("calloutAccessoryControlTapped 被調用")
            guard let annotation = view.annotation as? CustomAnnotation else {
                print("未找到 CustomAnnotation")
                return
            }
            
            let selectedSupermarket = annotation.supermarket
            print("找到選中的超市: \(selectedSupermarket.name)")
            
            DispatchQueue.main.async {
                self.parent.selectedSupermarket = selectedSupermarket
                self.parent.showingNavigationAlert = true
            }
        }
        
        // 選擇標註時記錄其 ID
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? CustomAnnotation {
                selectedSupermarketID = annotation.supermarket.id
            }
        }
        
        // 當標註被移除時清除選擇
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let annotation = view.annotation as? CustomAnnotation {
                if annotation.supermarket.id == selectedSupermarketID {
                    selectedSupermarketID = nil
                }
            }
        }
    }

    
    class CustomAnnotation: NSObject, MKAnnotation {
        let supermarket: Supermarket
        var coordinate: CLLocationCoordinate2D
        var title: String?
        var subtitle: String?
        
        init(supermarket: Supermarket) {
            self.supermarket = supermarket
            self.coordinate = supermarket.coordinate
            self.title = supermarket.name
            self.subtitle = supermarket.address
        }
    }

}

//import SwiftUI
//import MapKit
//
//// 自訂 MKAnnotation 類
//class CustomAnnotation: NSObject, MKAnnotation {
//    let supermarket: Supermarket
//    var coordinate: CLLocationCoordinate2D
//    var title: String?
//    var subtitle: String?
//
//    init(supermarket: Supermarket) {
//        self.supermarket = supermarket
//        self.coordinate = supermarket.coordinate
//        self.title = supermarket.name
//        self.subtitle = supermarket.address
//    }
//}
//
//struct CustomMapView: UIViewRepresentable {
//    @Binding var region: MKCoordinateRegion
//    @Binding var showingNavigationAlert: Bool
//    @Binding var selectedSupermarket: Supermarket?
//    var locationManager: LocationManager
//    var supermarkets: [Supermarket]
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.showsUserLocation = true
//        return mapView
//    }
//
//    func updateUIView(_ mapView: MKMapView, context: Context) {
//        if !locationManager.isUserInteracting {
//            // 只有當區域實際改變時才設置
//            if mapView.region.center.latitude != region.center.latitude ||
//                mapView.region.center.longitude != region.center.longitude ||
//                mapView.region.span.latitudeDelta != region.span.latitudeDelta ||
//                mapView.region.span.longitudeDelta != region.span.longitudeDelta {
//                mapView.setRegion(region, animated: true)
//            }
//        }
//        let previouslySelectedID = context.coordinator.selectedSupermarketID
//        updateAnnotations(mapView: mapView)
//
//        // 重新選中標註
//        if let selectedID = previouslySelectedID,
//           let annotation = mapView.annotations.compactMap({ $0 as? CustomAnnotation }).first(where: { $0.supermarket.id == selectedID }) {
//            mapView.selectAnnotation(annotation, animated: true)
//        }
//    }
//
//    private func updateAnnotations(mapView: MKMapView) {
//        let existingAnnotations = mapView.annotations.compactMap { $0 as? CustomAnnotation }
//        let existingSupermarketIDs = Set(existingAnnotations.map { $0.supermarket.id })
//        let newSupermarketIDs = Set(supermarkets.map { $0.id })
//
//        // 移除不再需要的標註
//        let supermarketsToRemove = existingSupermarketIDs.subtracting(newSupermarketIDs)
//        let annotationsToRemove = existingAnnotations.filter { supermarketsToRemove.contains($0.supermarket.id) }
//        mapView.removeAnnotations(annotationsToRemove)
//
//        // 添加新的標註
//        let supermarketsToAdd = newSupermarketIDs.subtracting(existingSupermarketIDs)
//        let supermarketsToAddList = supermarkets.filter { supermarketsToAdd.contains($0.id) }
//        for supermarket in supermarketsToAddList {
//            let annotation = CustomAnnotation(supermarket: supermarket)
//            mapView.addAnnotation(annotation)
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, MKMapViewDelegate {
//        var parent: CustomMapView
//        var selectedSupermarketID: String? // 使用 String 作為 ID 類型
//
//        init(_ parent: CustomMapView) {
//            self.parent = parent
//        }
//
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            guard let annotation = annotation as? CustomAnnotation else { return nil }
//            let identifier = "Supermarket"
//            var view: MKMarkerAnnotationView
//
//            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
//                view = dequeuedView
//                view.annotation = annotation
//            } else {
//                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                view.canShowCallout = true
//                view.calloutOffset = CGPoint(x: -5, y: 5)
//                let rightButton = UIButton(type: .detailDisclosure)
//                view.rightCalloutAccessoryView = rightButton
//            }
//
//            view.markerTintColor = .red
//            return view
//        }
//
//        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//            print("calloutAccessoryControlTapped 被調用")
//            guard let annotation = view.annotation as? CustomAnnotation else {
//                print("未找到 CustomAnnotation")
//                return
//            }
//
//            let selectedSupermarket = annotation.supermarket
//            print("找到選中的超市: \(selectedSupermarket.name)")
//
//            DispatchQueue.main.async {
//                self.parent.selectedSupermarket = selectedSupermarket
//                self.parent.showingNavigationAlert = true
//            }
//        }
//
//        // 選擇標註時記錄其 ID
//        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            if let annotation = view.annotation as? CustomAnnotation {
//                selectedSupermarketID = annotation.supermarket.id
//            }
//        }
//
//        // 當標註被移除時清除選擇
//        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
//            if let annotation = view.annotation as? CustomAnnotation {
//                if annotation.supermarket.id == selectedSupermarketID {
//                    selectedSupermarketID = nil
//                }
//            }
//        }
//    }
//}
