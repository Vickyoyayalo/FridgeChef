//
//  CustomMapView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/21.

import MapKit
import SwiftUI

struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var showingNavigationAlert: Bool
    @Binding var selectedSupermarket: Supermarket?
    var supermarkets: [Supermarket]
    var onRegionChange: ((MKCoordinateRegion) -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let tolerance: CLLocationDegrees = 0.0001
        let centerDifference = abs(mapView.region.center.latitude - region.center.latitude) +
        abs(mapView.region.center.longitude - region.center.longitude)
        let spanDifference = abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) +
        abs(mapView.region.span.longitudeDelta - region.span.longitudeDelta)
        
        if centerDifference > tolerance || spanDifference > tolerance {
            mapView.setRegion(region, animated: true)
        }
        
        let previouslySelectedID = context.coordinator.selectedSupermarketID
        updateAnnotations(mapView: mapView)
        
        if let selectedID = previouslySelectedID,
           let annotation = mapView.annotations.compactMap({ $0 as? CustomAnnotation }).first(where: { $0.supermarket.id == selectedID }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    private func updateAnnotations(mapView: MKMapView) {
        let existingAnnotations = mapView.annotations.compactMap { $0 as? CustomAnnotation }
        let existingSupermarketIDs = Set(existingAnnotations.map { $0.supermarket.id })
        let newSupermarketIDs = Set(supermarkets.map { $0.id })
        
        let supermarketsToRemove = existingSupermarketIDs.subtracting(newSupermarketIDs)
        let annotationsToRemove = existingAnnotations.filter { supermarketsToRemove.contains($0.supermarket.id) }
        mapView.removeAnnotations(annotationsToRemove)
        
        let supermarketsToAdd = newSupermarketIDs.subtracting(existingSupermarketIDs)
        let supermarketsToAddList = supermarkets.filter { supermarketsToAdd.contains($0.id) }
        for supermarket in supermarketsToAddList {
            let annotation = CustomAnnotation(supermarket: supermarket)
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onRegionChange: onRegionChange)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        var selectedSupermarketID: UUID?
        var interactionTimer: Timer?
        var onRegionChange: ((MKCoordinateRegion) -> Void)?
        
        init(_ parent: CustomMapView, onRegionChange: ((MKCoordinateRegion) -> Void)?) {
            self.parent = parent
            self.onRegionChange = onRegionChange
        }
        
        // MARK: - MKMapViewDelegate Methods
        
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
            guard let annotation = view.annotation as? CustomAnnotation else { return }
            let selectedSupermarket = annotation.supermarket
            
            DispatchQueue.main.async {
                self.parent.selectedSupermarket = selectedSupermarket
                self.parent.showingNavigationAlert = true
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? CustomAnnotation {
                selectedSupermarketID = annotation.supermarket.id
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let annotation = view.annotation as? CustomAnnotation,
               annotation.supermarket.id == selectedSupermarketID {
                selectedSupermarketID = nil
            }
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.interactionTimer?.invalidate()
                self.interactionTimer = nil
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.interactionTimer?.invalidate()
                self.interactionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    self.onRegionChange?(mapView.region)
                    self.interactionTimer = nil
                }
            }
        }
    }
    
    // MARK: - CustomAnnotation Class
    
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
