//
//  MapViewWithUserLocation.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/20.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @Binding var isPresented: Bool
    @FocusState private var isSearchFieldFocused: Bool
    
    init(locationManager: LocationManager, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MapViewModel(locationManager: locationManager))
        _isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            map
                .overlay(
                    (isSearchFieldFocused || !viewModel.searchText.isEmpty) && !viewModel.searchResults.isEmpty
                    ? Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    : nil
                )
            VStack {
                searchField
                if (isSearchFieldFocused || !viewModel.searchText.isEmpty) && !viewModel.searchResults.isEmpty {
                    listResults
                }
                Spacer()
                dismissButton
            }
        }
        .alert(isPresented: $viewModel.showingNavigationAlert) {
            Alert(
                title: Text("Go to ➡️ \(viewModel.selectedSupermarket?.name ?? "the selected location")？"),
                message: Text("📍Direction： \(viewModel.selectedSupermarket?.address ?? "")"),
                primaryButton: .default(Text("Let's GO 🛒"), action: {
                    viewModel.performNavigation()
                }),
                secondaryButton: .cancel()
            )
        }
    }
    
    private var searchField: some View {
        HStack(alignment: .center) {
            TextField("🔍 Search supermarkets nearby", text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) {
                    viewModel.updateSearchResults()
                }
                .focused($isSearchFieldFocused)
                .padding(.leading, 10)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
                .overlay(
                    HStack {
                        Spacer()
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                                isSearchFieldFocused = false
                            }, label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.gray)
                                    .padding(.trailing, 8)
                            })
                        }
                    }
                )
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var map: some View {
        CustomMapView(
            region: $viewModel.region,
            showingNavigationAlert: $viewModel.showingNavigationAlert,
            selectedSupermarket: $viewModel.selectedSupermarket,
            supermarkets: viewModel.searchResults.isEmpty && viewModel.searchText.isEmpty ? viewModel.allSupermarkets : viewModel.searchResults,
            onRegionChange: { newRegion in
                viewModel.region = newRegion
            }
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var listResults: some View {
        List(viewModel.searchResults, id: \.id) { supermarket in
            SupermarketRowView(supermarket: supermarket, userLocation: viewModel.userLocation)
                .onTapGesture {
                    viewModel.openDirections(to: supermarket)
                }
        }
        .padding(.horizontal)
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }
    
    private var dismissButton: some View {
        Button(action: {
            isPresented = false
        }, label: {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .padding()
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 5)
        })
        .padding()
    }
}
