//
//  CountryMapView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif
import CoreLocation

struct CountryMapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText = ""
    @State private var mapSelection: PhotoAnnotation?
    @State private var viewingPhotos = false
    @State private var showPhotoCapture = false
    @State private var showLocationPhotoAlbum = false
    
    // 添加搜索相关状态
    @State private var searchResults: [MKMapItem] = []
    @State private var searchIsActive = false
    @State private var selectedSearchResult: MKMapItem?
    
    // Sample photo annotations (in a real app, these would come from Firestore)
    @State private var photoAnnotations: [PhotoAnnotation] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, selection: $mapSelection) {
                    // 显示照片标记
                    ForEach(photoAnnotations) { annotation in
                        Marker(coordinate: annotation.coordinate) {
                            Image(systemName: "photo")
                                .tint(.blue)
                        }
                        .tag(annotation)
                    }
                    
                    // 显示搜索结果标记
                    ForEach(searchResults, id: \.self) { item in
                        Marker(item.name ?? "位置", coordinate: item.placemark.coordinate)
                            .tint(.red)
                    }
                    
                    // 如果有选中的搜索结果，使用不同的标记样式
                    if let selectedItem = selectedSearchResult {
                        Marker(selectedItem.name ?? "已选择位置", coordinate: selectedItem.placemark.coordinate)
                            .tint(.green)
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
                
                // 搜索结果列表
                if searchIsActive && !searchResults.isEmpty {
                    VStack {
                        List {
                            ForEach(searchResults, id: \.self) { item in
                                Button(action: {
                                    selectSearchResult(item)
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(item.name ?? "未知位置")
                                            .font(.headline)
                                        Text(formatAddress(for: item.placemark))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .frame(height: min(CGFloat(searchResults.count * 60), 300))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .shadow(radius: 5)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top))
                }
                
                // Camera button for capturing photos
                VStack {
                    Spacer()
                    
                    HStack {
                        // Show photo album button
                        Button(action: {
                            showLocationPhotoAlbum = true
                        }) {
                            Image(systemName: "photo.stack.fill")
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
            .compatibleSearchable(text: $searchText, prompt: "搜索地点")
            .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty && newValue.count >= 2 {
                    searchPlaces(with: newValue)
                    searchIsActive = true
                } else {
                    searchResults = []
                    searchIsActive = false
                }
            }
            .sheet(isPresented: $showPhotoCapture) {
                InlinePhotoCaptureView()
            }
            .sheet(isPresented: $showLocationPhotoAlbum) {
                InlineLocationPhotoAlbumView()
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
    
    // 实现地址搜索功能
    private func searchPlaces(with query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("搜索错误: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                self.searchResults = []
                return
            }
            
            self.searchResults = response.mapItems
        }
    }
    
    // 格式化地址
    private func formatAddress(for placemark: MKPlacemark) -> String {
        let components = [
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
            placemark.country
        ]
        
        return components.compactMap { $0 }.joined(separator: ", ")
    }
    
    // 选择搜索结果
    private func selectSearchResult(_ item: MKMapItem) {
        selectedSearchResult = item
        
        // 在地图上显示选定位置
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: item.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
        
        // 关闭搜索结果列表
        searchIsActive = false
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

// MARK: - 内联照片拍摄视图
#if os(iOS)
struct InlinePhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var currentLocation: CLLocationCoordinate2D?
    @State private var locationDescription = "获取位置中..."
    @State private var cameraAvailable = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let image = capturedImage {
                    // Show the captured image with location info
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                    
                    Text(locationDescription)
                        .font(.headline)
                        .padding()
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            if cameraAvailable {
                                capturedImage = nil
                                showingCamera = true
                            } else {
                                // 提示用户相机不可用
                                print("相机不可用")
                            }
                        }) {
                            Text("重拍")
                                .font(.headline)
                                .padding()
                                .frame(minWidth: 120)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .disabled(!cameraAvailable)
                        
                        Button(action: {
                            savePhoto()
                            dismiss()
                        }) {
                            Text("保存")
                                .font(.headline)
                                .padding()
                                .frame(minWidth: 120)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)
                } else {
                    if !cameraAvailable {
                        // 相机不可用时显示提示
                        VStack(spacing: 20) {
                            Image(systemName: "camera.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("相机不可用")
                                .font(.headline)
                            
                            Text("请在真机上运行或检查相机权限")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("关闭") {
                                dismiss()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 20)
                        }
                        .padding()
                    } else {
                        // 加载相机中的占位图
                        ZStack {
                            Color.black
                                .compatibleIgnoresSafeArea()
                            
                            Text("加载相机...")
                                .foregroundColor(.white)
                                .font(.title)
                        }
                    }
                }
            }
            .navigationTitle("拍照")
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.compatibleTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 检查相机可用性
                cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
                
                // 只有当相机可用时才启动位置更新和相机
                if cameraAvailable {
                    startLocationUpdates()
                    // 延迟一点启动相机，避免UI阻塞
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingCamera = true
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $capturedImage, sourceType: .camera, onDismiss: {
                    if capturedImage != nil {
                        getLocationDescription()
                    } else {
                        dismiss()
                    }
                })
            }
        }
    }
    
    private func startLocationUpdates() {
        // In a real app, you would use CLLocationManager to get the user's location
        // For this demo, we'll simulate a location in Shanghai
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentLocation = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
            self.getLocationDescription()
        }
    }
    
    private func getLocationDescription() {
        guard let _ = currentLocation else { return }
        
        // In a real app, you would use CLGeocoder to reverse geocode the location
        // For this demo, we'll just use a hardcoded value
        self.locationDescription = "上海市"
    }
    
    private func savePhoto() {
        // In a real app, you would save the image to local storage and database
        // along with the location information
        print("Photo saved with location: \(locationDescription)")
    }
}

// UIImagePickerController SwiftUI wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // 检查设备是否支持指定的sourceType
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            // 如果不支持（如模拟器无相机），则使用默认的photoLibrary
            picker.sourceType = .photoLibrary
        }
        
        // 设置委托
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true) {
                self.parent.onDismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.parent.onDismiss()
            }
        }
    }
}
#else
// 为非iOS平台提供一个简单的替代实现
struct InlinePhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("相机功能仅在iOS设备上可用")
                .font(.headline)
                .padding()
            
            Button("关闭") {
                dismiss()
            }
            .padding()
        }
    }
}
#endif

// MARK: - 内联位置照片专辑视图
struct InlineLocationPhotoAlbumView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Sample location data
    @State private var photoLocations: [LocationPhotoCollection] = sampleLocationPhotoCollections
    @State private var selectedLocation: LocationPhotoCollection?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(photoLocations) { location in
                        LocationAlbumSection(location: location) {
                            selectedLocation = location
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationTitle("照片地点")
            .compatibleNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.compatibleTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedLocation) { location in
                LocationPhotoDetailView(location: location)
            }
        }
    }
}

struct LocationAlbumSection: View {
    let location: LocationPhotoCollection
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location header
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                
                Text(location.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(location.photos.count) 张照片")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Photo preview grid
            let previewPhotos = Array(location.photos.prefix(4))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(previewPhotos) { photo in
                    SafeAsyncImage(url: URL(string: photo.url)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "photo")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // "View all" button
            Button(action: onTap) {
                HStack {
                    Text("查看全部")
                        .font(.headline)
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct SafeAsyncImage<Content: View, Placeholder: View>: View {
    var url: URL?
    var content: (Image) -> Content
    var placeholder: () -> Placeholder
    
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let url = url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder()
                case .success(let image):
                    content(image)
                case .failure(_):
                    // 显示错误状态
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    }
                @unknown default:
                    placeholder()
                }
            }
        } else {
            placeholder()
        }
    }
}

struct LocationPhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let location: LocationPhotoCollection
    
    // Grid layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Map preview
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )))) {
                    Marker(coordinate: location.coordinate) {
                        Image(systemName: "photo")
                            .tint(.blue)
                    }
                }
                .frame(height: 150)
                .disabled(true)
                
                // Photo grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(location.photos) { photo in
                            SafeAsyncImage(url: URL(string: photo.url)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ZStack {
                                    Color.gray.opacity(0.3)
                                    Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                }
                            }
                            .aspectRatio(1, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipShape(Rectangle())
                        }
                    }
                    .padding(4)
                }
            }
            .navigationTitle(location.name)
            .compatibleNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.compatibleTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Model for location photo collections
struct LocationPhotoCollection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let photos: [PhotoItem]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LocationPhotoCollection, rhs: LocationPhotoCollection) -> Bool {
        lhs.id == rhs.id
    }
}

// Model for individual photos
struct PhotoItem: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let date: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Sample data
let sampleLocationPhotoCollections = [
    LocationPhotoCollection(
        name: "上海市",
        coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        photos: (1...8).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "北京市",
        coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        photos: (9...15).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "杭州市",
        coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
        photos: (16...23).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "成都市",
        coordinate: CLLocationCoordinate2D(latitude: 30.5728, longitude: 104.0668),
        photos: (24...30).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    ),
    LocationPhotoCollection(
        name: "广州市",
        coordinate: CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644),
        photos: (31...38).map { PhotoItem(url: "https://picsum.photos/500/500?random=\($0)", date: Date().addingTimeInterval(-Double($0) * 86400)) }
    )
]

#Preview {
    CountryMapView()
} 