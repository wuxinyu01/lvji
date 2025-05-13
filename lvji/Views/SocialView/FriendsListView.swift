//
//  FriendsListView.swift
//  lvji
//
//  Created by wxy-Mac on 2025/5/8.
//

import SwiftUI

struct FriendsListView: View {
    @State private var friends: [FriendItem] = sampleFriends
    @State private var sharedPhotos: [SharedPhoto] = samplePhotos
    @State private var showAddFriend = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("路线规划").font(.headline)) {
                    NavigationLink(destination: Text("个人旅行计划界面")) {
                        HStack {
                            Image(systemName: "map.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            Text("个人旅行计划")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    NavigationLink(destination: Text("路线规划界面")) {
                        HStack {
                            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            Text("与好友会合")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("好友").font(.headline)) {
                    ForEach(friends) { friend in
                        NavigationLink(destination: FriendDetailView(friend: friend)) {
                            FriendRow(friend: friend)
                        }
                    }
                }
                
                Section(header: Text("共享照片").font(.headline)) {
                    SharedPhotosView(photos: sharedPhotos)
                }
            }
            .navigationTitle("奔赴")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
            }
        }
    }
}

struct FriendRow: View {
    let friend: FriendItem
    
    var body: some View {
        HStack {
            if let imageUrl = friend.profileImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray.opacity(0.5))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading) {
                Text(friend.name)
                    .font(.headline)
                Text(friend.lastUpdateDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            if friend.isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SharedPhotosView: View {
    let photos: [SharedPhoto]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(photos) { photo in
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: photo.url)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        HStack {
                            Text(photo.location)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(5)
                        }
                        .padding(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 140)
    }
}

struct FriendDetailView: View {
    let friend: FriendItem
    @State private var showRouteOptions = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Friend profile header
                HStack {
                    if let imageUrl = friend.profileImageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(friend.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(friend.isOnline ? "在线" : "离线")
                            .font(.subheadline)
                            .foregroundColor(friend.isOnline ? .green : .gray)
                        
                        Text("上次更新: \(friend.lastUpdateDescription)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Action buttons
                HStack {
                    Button(action: {
                        // Send message
                    }) {
                        Label("发消息", systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        showRouteOptions = true
                    }) {
                        Label("规划路线", systemImage: "map.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                // Recent shared photos section
                Text("最近分享")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(samplePhotos) { photo in
                            AsyncImage(url: URL(string: photo.url)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Recent locations section
                Text("最近位置")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // This would be a map view in a real implementation
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRouteOptions) {
            Text("路线规划选项")
                .font(.title)
                .padding()
        }
    }
}

struct AddFriendView: View {
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("查找好友")) {
                        TextField("输入用户名或ID", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 8)
                        
                        Button(action: {
                            // Search for friends
                        }) {
                            Text("搜索")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if !searchText.isEmpty {
                        Section(header: Text("搜索结果")) {
                            ForEach(1...3, id: \.self) { i in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text("用户 \(i)")
                                            .font(.headline)
                                        Text("ID: user\(i)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Add friend
                                    }) {
                                        Text("添加")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加好友")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Sample data for UI development
struct FriendItem: Identifiable {
    let id: String
    let name: String
    let profileImageUrl: String?
    let isOnline: Bool
    let lastUpdateDescription: String
}

struct SharedPhoto: Identifiable {
    let id: String
    let url: String
    let location: String
    let timestamp: Date
}

let sampleFriends = [
    FriendItem(id: "1", name: "张三", profileImageUrl: nil, isOnline: true, lastUpdateDescription: "30分钟前"),
    FriendItem(id: "2", name: "李四", profileImageUrl: nil, isOnline: false, lastUpdateDescription: "1小时前"),
    FriendItem(id: "3", name: "王五", profileImageUrl: nil, isOnline: true, lastUpdateDescription: "刚刚"),
    FriendItem(id: "4", name: "赵六", profileImageUrl: nil, isOnline: false, lastUpdateDescription: "昨天"),
    FriendItem(id: "5", name: "钱七", profileImageUrl: nil, isOnline: true, lastUpdateDescription: "3小时前")
]

let samplePhotos = [
    SharedPhoto(id: "1", url: "https://example.com/photo1.jpg", location: "北京", timestamp: Date()),
    SharedPhoto(id: "2", url: "https://example.com/photo2.jpg", location: "上海", timestamp: Date()),
    SharedPhoto(id: "3", url: "https://example.com/photo3.jpg", location: "广州", timestamp: Date()),
    SharedPhoto(id: "4", url: "https://example.com/photo4.jpg", location: "深圳", timestamp: Date()),
    SharedPhoto(id: "5", url: "https://example.com/photo5.jpg", location: "杭州", timestamp: Date()),
    SharedPhoto(id: "6", url: "https://example.com/photo6.jpg", location: "成都", timestamp: Date()),
    SharedPhoto(id: "7", url: "https://example.com/photo7.jpg", location: "西安", timestamp: Date()),
    SharedPhoto(id: "8", url: "https://example.com/photo8.jpg", location: "南京", timestamp: Date())
]

#Preview {
    FriendsListView()
} 