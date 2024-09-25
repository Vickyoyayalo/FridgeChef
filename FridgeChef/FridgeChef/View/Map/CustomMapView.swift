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
            // 定义一个小的容差，避免浮点精度问题导致的频繁更新
            let tolerance: CLLocationDegrees = 0.0001
            let centerDifference = abs(mapView.region.center.latitude - region.center.latitude) +
                                   abs(mapView.region.center.longitude - region.center.longitude)
            let spanDifference = abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) +
                                 abs(mapView.region.span.longitudeDelta - region.span.longitudeDelta)

            // 仅当差异超过容差时才更新区域
            if centerDifference > tolerance || spanDifference > tolerance {
                mapView.setRegion(region, animated: true)
            }
        }

        // 更新标注
        let previouslySelectedID = context.coordinator.selectedSupermarketID
        updateAnnotations(mapView: mapView)

        // 重新选中标注
        if let selectedID = previouslySelectedID,
           let annotation = mapView.annotations.compactMap({ $0 as? CustomAnnotation }).first(where: { $0.supermarket.id == selectedID }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }

    private func updateAnnotations(mapView: MKMapView) {
        // 现有的 CustomAnnotation
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
        var interactionTimer: Timer?

        init(_ parent: CustomMapView) {
            self.parent = parent
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
            print("calloutAccessoryControlTapped 被调用")
            guard let annotation = view.annotation as? CustomAnnotation else {
                print("未找到 CustomAnnotation")
                return
            }

            let selectedSupermarket = annotation.supermarket
            print("找到选中的超市: \(selectedSupermarket.name)")

            DispatchQueue.main.async {
                self.parent.selectedSupermarket = selectedSupermarket
                self.parent.showingNavigationAlert = true
            }
        }

        // 选中标注时记录其 ID
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? CustomAnnotation {
                selectedSupermarketID = annotation.supermarket.id
            }
        }

        // 当标注被移除时清除选择
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let annotation = view.annotation as? CustomAnnotation {
                if annotation.supermarket.id == selectedSupermarketID {
                    selectedSupermarketID = nil
                }
            }
        }

        // 用户开始交互时
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.locationManager.isUserInteracting = true
                // 取消之前的定时器
                self.interactionTimer?.invalidate()
                self.interactionTimer = nil
            }
        }

        // 用户结束交互时
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                // 取消之前的定时器
                self.interactionTimer?.invalidate()
                // 启动一个新的定时器，延迟将 isUserInteracting 设为 false
                self.interactionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    self.parent.locationManager.isUserInteracting = false
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
