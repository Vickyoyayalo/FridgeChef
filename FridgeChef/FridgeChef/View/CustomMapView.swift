//
//  CustomMapView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/21.
//

import SwiftUI
import MapKit

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
            mapView.setRegion(region, animated: true)
        }
        updateAnnotations(mapView: mapView)
    }
    
    //     TODO 更新地圖上的標記
    private func updateAnnotations(mapView: MKMapView) {
        let currentAnnotations = mapView.annotations.compactMap { $0 as? MKPointAnnotation }
        let currentCoordinates = Set(currentAnnotations.map { $0.coordinate })
        let newCoordinates = Set(supermarkets.map { $0.coordinate })
        
        // 找出需要移除的标注
        let annotationsToRemove = currentAnnotations.filter { !newCoordinates.contains($0.coordinate) }
        mapView.removeAnnotations(annotationsToRemove)
        
        // 找出需要添加的新标注
        let coordinatesToAdd = newCoordinates.subtracting(currentCoordinates)
        for coordinate in coordinatesToAdd {
            if let supermarket = supermarkets.first(where: { $0.coordinate == coordinate }) {
                let annotation = MKPointAnnotation()
                annotation.coordinate = supermarket.coordinate
                annotation.title = supermarket.name
                annotation.subtitle = supermarket.address
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        // 自訂標記視圖
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? MKPointAnnotation else { return nil }
            let identifier = "Supermarket"
            var view: MKMarkerAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = dequeuedView
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                // 添加一个详情按钮作为callout的一部分
                let rightButton = UIButton(type: .detailDisclosure)
                
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            view.markerTintColor = .red
            return view
        }
        
        // 點擊標記後觸發
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKPointAnnotation else { return }
            
            // 找到对应的超市
            if let selectedSupermarket = parent.supermarkets.first(where: {
                $0.coordinate.latitude == annotation.coordinate.latitude &&
                $0.coordinate.longitude == annotation.coordinate.longitude
            }) {
                DispatchQueue.main.async {
                    self.parent.selectedSupermarket = selectedSupermarket
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? MKPointAnnotation else { return }
            
            // 点击 callout 详情按钮后进入导航
            if let selectedSupermarket = parent.supermarkets.first(where: {
                $0.coordinate.latitude == annotation.coordinate.latitude &&
                $0.coordinate.longitude == annotation.coordinate.longitude
            }) {
                DispatchQueue.main.async {
                    self.parent.selectedSupermarket = selectedSupermarket
                    self.parent.showingNavigationAlert = true
                }
            }
        }
    }
}
// 扩展 CLLocationCoordinate2D 以支持 Hashable
extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return abs(lhs.latitude - rhs.latitude) < 0.000001 &&
        abs(lhs.longitude - rhs.longitude) < 0.000001
    }
}

