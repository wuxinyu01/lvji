//
//  UserProfileView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI
import MapKit

// 定义全局变量，以避免对FriendsListView中变量的引用
let sampleFriendsCount = 5

struct UserProfileView: View {
    @State private var showingEditProfile = false
    @State private var showPhotosMap = false
    
    // Sample user data (would be fetched from user authentication service in a real app)
    @State private var userData: UserProfile = UserProfile(
        id: "user123",
        username: "旅行者",
        profileImage: nil,
        totalPhotos: 42,
        totalCountries: 7,
        joinDate: Date().addingTimeInterval(-60*60*24*90) // 90 days ago
    )
    
    var body: some View {
        NavigationStack {
            List {
                // Profile header section
                Section {
                    HStack {
                        if let profileImage = userData.profileImage {
                            AsyncImage(url: URL(string: profileImage)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .frame(width: 80, height: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userData.username)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                Text("编辑个人资料")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("加入于 \(formatDate(userData.joinDate))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    // Stats row
                    HStack {
                        VStack {
                            Text("\(userData.totalPhotos)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("照片")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("\(userData.totalCountries)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("国家")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("\(sampleFriendsCount)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("好友")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
                
                // My footprints section
                Section(header: Text("我的足迹").font(.headline)) {
                    NavigationLink(destination: PhotoGalleryView()) {
                        Label("我的照片", systemImage: "photo.on.rectangle")
                            .padding(.vertical, 8)
                    }
                    
                    Button(action: {
                        showPhotosMap = true
                    }) {
                        Label("照片地图", systemImage: "map")
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    
                    NavigationLink(destination: Text("旅行统计")) {
                        Label("旅行统计", systemImage: "chart.bar")
                            .padding(.vertical, 8)
                    }
                }
                
                // Settings section
                Section(header: Text("设置").font(.headline)) {
                    NavigationLink(destination: Text("账号设置")) {
                        Label("账号设置", systemImage: "person.crop.circle")
                            .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: Text("隐私设置")) {
                        Label("隐私设置", systemImage: "hand.raised")
                            .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: Text("通知")) {
                        Label("通知", systemImage: "bell")
                            .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: Text("存储与数据")) {
                        Label("存储与数据", systemImage: "internaldrive")
                            .padding(.vertical, 8)
                    }
                }
                
                // About section
                Section(header: Text("关于").font(.headline)) {
                    NavigationLink(destination: Text("帮助中心")) {
                        Label("帮助中心", systemImage: "questionmark.circle")
                            .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: Text("关于旅迹")) {
                        Label("关于旅迹", systemImage: "info.circle")
                            .padding(.vertical, 8)
                    }
                    
                    Button(action: {
                        // Log out functionality
                    }) {
                        Label("退出登录", systemImage: "arrow.left.square")
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(userData: $userData)
            }
            .sheet(isPresented: $showPhotosMap) {
                PhotosMapView()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct PhotoGalleryView: View {
    // Sample grid of photos
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1...30, id: \.self) { i in
                    ZStack {
                        Color.gray.opacity(0.3)
                            .aspectRatio(1, contentMode: .fill)
                        
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                    .clipShape(Rectangle())
                }
            }
            .padding(4)
        }
        .navigationTitle("我的照片")
    }
}

struct PhotosMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // Sample photo locations
    @State private var photoLocations: [PhotoLocation] = samplePhotoLocations
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(photoLocations) { location in
                    Marker(coordinate: location.coordinate) {
                        Image(systemName: "photo")
                            .tint(.blue)
                    }
                    .tag(location)
                }
            }
            .mapStyle(.standard)
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("照片地图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Binding var userData: UserProfile
    @State private var username: String
    @Environment(\.dismiss) private var dismiss
    
    init(userData: Binding<UserProfile>) {
        self._userData = userData
        self._username = State(initialValue: userData.wrappedValue.username)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("照片")) {
                    HStack {
                        Spacer()
                        
                        VStack {
                            if let profileImage = userData.profileImage {
                                AsyncImage(url: URL(string: profileImage)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.blue)
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 100))
                                    .foregroundColor(.blue)
                                    .frame(width: 120, height: 120)
                            }
                            
                            Button("更换头像") {
                                // Photo picker would be implemented here
                            }
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
                
                Section(header: Text("个人信息")) {
                    TextField("用户名", text: $username)
                        .padding(.vertical, 8)
                }
                
                Button(action: {
                    // Save profile changes
                    userData.username = username
                    dismiss()
                }) {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
            .navigationTitle("编辑个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UserProfile {
    var id: String
    var username: String
    var profileImage: String?
    var totalPhotos: Int
    var totalCountries: Int
    var joinDate: Date
}

struct PhotoLocation: Identifiable, Hashable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    
    // CLLocationCoordinate2D 不符合 Hashable 协议，所以我们需要自己实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
    
    static func == (lhs: PhotoLocation, rhs: PhotoLocation) -> Bool {
        return lhs.id == rhs.id &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

let samplePhotoLocations = [
    PhotoLocation(id: "1", coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)), // Shanghai
    PhotoLocation(id: "2", coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)), // Beijing
    PhotoLocation(id: "3", coordinate: CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579)), // Shenzhen
    PhotoLocation(id: "4", coordinate: CLLocationCoordinate2D(latitude: 30.5728, longitude: 104.0668)), // Chengdu
    PhotoLocation(id: "5", coordinate: CLLocationCoordinate2D(latitude: 34.3416, longitude: 108.9398)), // Xi'an
    PhotoLocation(id: "6", coordinate: CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644)), // Guangzhou
    PhotoLocation(id: "7", coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551)), // Hangzhou
    PhotoLocation(id: "8", coordinate: CLLocationCoordinate2D(latitude: 32.0584, longitude: 118.7964))  // Nanjing
]

#Preview {
    UserProfileView()
} 