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
    @State private var pinnedFriends: [FriendItem] = []
    
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
                    
                    NavigationLink(destination: RouteSelectionView()) {
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
                
                if !pinnedFriends.isEmpty {
                    Section(header: Text("置顶好友").font(.headline)) {
                        ForEach(pinnedFriends) { friend in
                            NavigationLink(destination: FriendDetailView(friend: friend)) {
                                FriendRow(friend: friend, isPinned: true) { isPinned in
                                    togglePin(for: friend, isPinned: isPinned)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("好友").font(.headline)) {
                    ForEach(friends.filter { friend in !pinnedFriends.contains { $0.id == friend.id } }) { friend in
                        NavigationLink(destination: FriendDetailView(friend: friend)) {
                            FriendRow(friend: friend, isPinned: false) { isPinned in
                                togglePin(for: friend, isPinned: isPinned)
                            }
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
    
    private func togglePin(for friend: FriendItem, isPinned: Bool) {
        if isPinned {
            // Remove from pinned
            pinnedFriends.removeAll { $0.id == friend.id }
        } else {
            // Add to pinned
            pinnedFriends.append(friend)
        }
    }
}

struct FriendRow: View {
    let friend: FriendItem
    let isPinned: Bool
    let onTogglePin: (Bool) -> Void
    
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
            
            Button(action: {
                onTogglePin(isPinned)
            }) {
                Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                    .foregroundColor(isPinned ? .blue : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
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
    @State private var showMessageView = false
    
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
                        showMessageView = true
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
            FriendRouteOptionsView(friend: friend)
        }
        .sheet(isPresented: $showMessageView) {
            MessageView(friend: friend)
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

// Additional models for the new features
struct Message: Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    var isRead: Bool
}

// Sample messages for UI development
let sampleMessages = [
    Message(id: "1", senderId: "self", receiverId: "1", content: "你好，最近怎么样？", timestamp: Date().addingTimeInterval(-3600 * 24 * 3), isRead: true),
    Message(id: "2", senderId: "1", receiverId: "self", content: "挺好的，准备去旅行", timestamp: Date().addingTimeInterval(-3600 * 24 * 3 + 60), isRead: true),
    Message(id: "3", senderId: "self", receiverId: "1", content: "去哪里旅行？", timestamp: Date().addingTimeInterval(-3600 * 24 * 2), isRead: true),
    Message(id: "4", senderId: "1", receiverId: "self", content: "我想去山西看看", timestamp: Date().addingTimeInterval(-3600 * 24 * 2 + 300), isRead: true),
    Message(id: "5", senderId: "self", receiverId: "1", content: "好啊，可以一起规划一下", timestamp: Date().addingTimeInterval(-3600 * 5), isRead: true),
    Message(id: "6", senderId: "1", receiverId: "self", content: "好的，你有什么建议吗？", timestamp: Date().addingTimeInterval(-3600 * 4), isRead: true),
    Message(id: "7", senderId: "self", receiverId: "1", content: "我们可以去平遥古城看看", timestamp: Date().addingTimeInterval(-3600 * 2), isRead: true),
    Message(id: "8", senderId: "1", receiverId: "self", content: "听起来不错！", timestamp: Date().addingTimeInterval(-3600), isRead: true)
]

// New Views for the requested features

struct MessageView: View {
    let friend: FriendItem
    @State private var messages: [Message] = sampleMessages
    @State private var newMessageText = ""
    @State private var pinnedMessageIds: Set<String> = []
    
    var body: some View {
        VStack {
            // Messages list
            ScrollViewReader { scrollView in
                List {
                    // Pinned messages section
                    if !pinnedMessageIds.isEmpty {
                        Section(header: Text("置顶消息")) {
                            ForEach(messages.filter { pinnedMessageIds.contains($0.id) }) { message in
                                MessageRow(message: message, isPinned: true) { isPinned in
                                    togglePinMessage(message, isPinned: isPinned)
                                }
                            }
                        }
                    }
                    
                    // Regular messages section
                    Section {
                        ForEach(messages.filter { !pinnedMessageIds.contains($0.id) }.sorted(by: { $0.timestamp > $1.timestamp })) { message in
                            MessageRow(message: message, isPinned: false) { isPinned in
                                togglePinMessage(message, isPinned: isPinned)
                            }
                        }
                    }
                }
                .onChange(of: messages.count) { 
                    if let lastMessage = messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input
            HStack {
                TextField("输入消息...", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
                .disabled(newMessageText.isEmpty)
            }
            .padding(.vertical)
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        let newMessage = Message(
            id: UUID().uuidString,
            senderId: "self",
            receiverId: friend.id,
            content: newMessageText,
            timestamp: Date(),
            isRead: true
        )
        messages.append(newMessage)
        newMessageText = ""
        
        // Simulate friend's response after a short delay
        if friend.isOnline {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let response = Message(
                    id: UUID().uuidString,
                    senderId: friend.id,
                    receiverId: "self",
                    content: "好的，收到了👌",
                    timestamp: Date(),
                    isRead: true
                )
                messages.append(response)
            }
        }
    }
    
    private func togglePinMessage(_ message: Message, isPinned: Bool) {
        if isPinned {
            pinnedMessageIds.remove(message.id)
        } else {
            pinnedMessageIds.insert(message.id)
        }
    }
}

struct MessageRow: View {
    let message: Message
    let isPinned: Bool
    let onTogglePin: (Bool) -> Void
    
    var isSentByMe: Bool {
        message.senderId == "self"
    }
    
    var body: some View {
        HStack {
            if isSentByMe {
                Spacer()
                
                // Pin/unpin button
                Button(action: {
                    onTogglePin(isPinned)
                }) {
                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                        .foregroundColor(isPinned ? .blue : .gray)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                // Message bubble
                Text(message.content)
                    .padding(10)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            } else {
                // Message bubble
                Text(message.content)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                // Pin/unpin button
                Button(action: {
                    onTogglePin(isPinned)
                }) {
                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                        .foregroundColor(isPinned ? .blue : .gray)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .background(isPinned ? Color.yellow.opacity(0.1) : Color.clear)
    }
}

struct RouteSelectionView: View {
    @State private var selectedFriends: [FriendItem] = []
    @State private var searchText = ""
    @State private var destination = ""
    @State private var showRouteResult = false
    
    var filteredFriends: [FriendItem] {
        if searchText.isEmpty {
            return sampleFriends
        } else {
            return sampleFriends.filter { $0.name.contains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            // Destination input
            TextField("输入目的地", text: $destination)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Selected friends
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(selectedFriends) { friend in
                        HStack {
                            Text(friend.name)
                            Button(action: {
                                selectedFriends.removeAll { $0.id == friend.id }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: selectedFriends.isEmpty ? 0 : 50)
            
            // Friends search
            TextField("搜索好友", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            List {
                ForEach(filteredFriends) { friend in
                    HStack {
                        Text(friend.name)
                        Spacer()
                        if selectedFriends.contains(where: { $0.id == friend.id }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
                            selectedFriends.remove(at: index)
                        } else {
                            selectedFriends.append(friend)
                        }
                    }
                }
            }
            
            // Plan route button
            Button(action: {
                showRouteResult = true
            }) {
                Text("开始规划路线")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedFriends.isEmpty || destination.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(selectedFriends.isEmpty || destination.isEmpty)
            .padding()
        }
        .navigationTitle("与好友会合")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRouteResult) {
            FriendRouteResultView(friends: selectedFriends, destination: destination)
        }
    }
}

struct FriendRouteOptionsView: View {
    let friend: FriendItem
    @State private var myLocation = ""
    @State private var destination = ""
    @State private var showRouteResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("与 \(friend.name) 规划路线")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("你的出发地", text: $myLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("目的地", text: $destination)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Text("等待 \(friend.name) 输入他的位置...")
                .foregroundColor(.gray)
                .padding()
            
            // Just for demo purposes, assume friend has input their location after 2 seconds
            Button(action: {
                showRouteResult = true
            }) {
                Text("开始规划")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(myLocation.isEmpty || destination.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(myLocation.isEmpty || destination.isEmpty)
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showRouteResult) {
            FriendRouteResultView(friends: [friend], destination: destination)
        }
    }
}

struct FriendRouteResultView: View {
    let friends: [FriendItem]
    let destination: String
    
    var body: some View {
        VStack {
            Text("路线规划结果")
                .font(.title)
                .padding()
            
            // Mock map view
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
                .overlay(
                    Image(systemName: "map")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                )
                .cornerRadius(10)
                .padding()
            
            VStack(alignment: .leading) {
                Text("目的地: \(destination)")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                Text("参与者:")
                    .font(.headline)
                
                ForEach(friends) { friend in
                    HStack {
                        Text("• \(friend.name)")
                        Spacer()
                        Text("已确认")
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 2)
                }
                
                Text("预计到达时间: 1小时30分钟")
                    .font(.headline)
                    .padding(.top, 10)
            }
            .padding()
            
            Button(action: {
                // Share route info
            }) {
                Label("分享路线", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    FriendsListView()
} 