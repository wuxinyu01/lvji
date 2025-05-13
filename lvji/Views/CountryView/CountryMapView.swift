//
//  CountryMapView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import MapKit

struct CountryMapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var mapSelection: PhotoAnnotation?
    @State private var viewingPhotos = false
    @State private var showPhotoCapture = false
    
    // Sample photo annotations (in a real app, these would come from Firestore)
    @State private var photoAnnotations: [PhotoAnnotation] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, selection: $mapSelection) {
                    // Display photo markers on the map
                    ForEach(photoAnnotations) { annotation in
                        Marker(coordinate: annotation.coordinate) {
                            // Custom marker view could be added here
                            Image(systemName: "photo")
                                .tint(.blue)
                        }
                        .tag(annotation)
                    }
                }
                .mapStyle(.standard)
                .edgesIgnoringSafeArea(.all)
                .onChange(of: mapSelection) { _, newValue in
                    if let selection = newValue {
                        // Handle selection of a photo marker
                        print("Selected photo: \(selection.id)")
                    }
                }
                
                // Camera button for capturing photos
                VStack {
                    Spacer()
                    
                    HStack {
                        // Show nearby photos button
                        Button(action: {
                            viewingPhotos.toggle()
                        }) {
                            Image(systemName: viewingPhotos ? "photo.fill" : "photo")
                                .font(.system(size: 22))
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.leading, 30)
                        
                        Spacer()
                        
                        // Camera button
                        Button(action: {
                            showPhotoCapture = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                    .shadow(radius: 4)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        // My location button
                        Button(action: {
                            centerOnUserLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 22))
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 30)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("旅迹")
            .searchable(text: $searchText, prompt: "搜索地点")
            .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty {
                    searchPlaces(with: newValue)
                }
            }
            .sheet(isPresented: $showPhotoCapture) {
                Text("拍照界面")
                    .font(.title)
                    .padding()
                // In a real app, you would implement a camera view here
            }
        }
        .onAppear {
            // Request location authorization when the view appears
            requestLocationPermission()
            // Load sample photo annotations
            loadSamplePhotoAnnotations()
        }
    }
    
    // Request permission to use location services
    private func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Center the map on the user's current location
    private func centerOnUserLocation() {
        cameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    }
    
    // Search for places based on the search text
    private func searchPlaces(with query: String) {
        // In a real app, you would implement MapKit search functionality here
        print("Searching for: \(query)")
    }
    
    // Load sample photo annotations (in a real app, these would come from Firestore)
    private func loadSamplePhotoAnnotations() {
        // Sample locations around the world
        let locations = [
            CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // New York
            CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Los Angeles
            CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), // London
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), // Tokyo
            CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)  // Beijing
        ]
        
        // Create photo annotations
        for (index, location) in locations.enumerated() {
            let annotation = PhotoAnnotation(
                id: "photo\(index)",
                coordinate: location,
                imageUrl: "sample_url_\(index)",
                timestamp: Date()
            )
            photoAnnotations.append(annotation)
        }
    }
}

// Model for photo map annotations
struct PhotoAnnotation: Identifiable, Hashable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let imageUrl: String
    let timestamp: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoAnnotation, rhs: PhotoAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    CountryMapView()
} 