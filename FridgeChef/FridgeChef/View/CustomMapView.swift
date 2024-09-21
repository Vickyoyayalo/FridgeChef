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
        updateAnnotations(from: mapView)
    }

    private func updateAnnotations(from mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        for supermarket in supermarkets {
            let annotation = MKPointAnnotation()
            annotation.coordinate = supermarket.coordinate
            annotation.title = supermarket.name
            mapView.addAnnotation(annotation)
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

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let _ = annotation as? MKPointAnnotation else { return nil }
            let identifier = "Supermarket"
            var view: MKMarkerAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = dequeuedView
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            view.markerTintColor = .red
            return view
        }

        // 当选择地标时
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKPointAnnotation else { return }
            if let selectedSupermarket = parent.supermarkets.first(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                DispatchQueue.main.async {
                    self.parent.selectedSupermarket = selectedSupermarket
                }
            }
        }
    }
}

//import SwiftUI
//import MapKit
//
//struct CustomMapView: UIViewRepresentable {
//    @Binding var region: MKCoordinateRegion
//    @Binding var selectedSupermarket: Supermarket?
//    @Binding var searchText: String
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
//        if locationManager.isUserInteracting {
//            return
//        }
//
//        let region = MKCoordinateRegion(center: locationManager.region.center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
//        mapView.setRegion(region, animated: true)
//
//        updateAnnotations(from: mapView)
//    }
//
//    private func updateAnnotations(from mapView: MKMapView) {
//        mapView.removeAnnotations(mapView.annotations)
//        let filteredSupermarkets = supermarkets.filter {
//            searchText.isEmpty || $0.name.contains(searchText)
//        }
//        for supermarket in filteredSupermarkets {
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = supermarket.coordinate
//            annotation.title = supermarket.name
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
//
//        init(_ parent: CustomMapView) {
//            self.parent = parent
//        }
//
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            guard let _ = annotation as? MKPointAnnotation else { return nil }
//            let identifier = "Supermarket"
//            var view: MKMarkerAnnotationView
//            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
//                view = dequeuedView
//            } else {
//                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//                view.canShowCallout = true
//                view.calloutOffset = CGPoint(x: -5, y: 5)
//                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
//            }
//            view.markerTintColor = .red
//            return view
//        }
//    }
//}
