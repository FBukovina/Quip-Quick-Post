//
//  PostCardView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    var onUpdate: (Post) -> Void
    var onDelete: () -> Void
    
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var showCommentsSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                WebImage(url: post.userProfileURL)
                    .resizable()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.userName)
                        .fontWeight(.semibold)
                    Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if post.userUID == userUID {
                    Menu {
                        Button("Delete", role: .destructive) { deletePost() }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            
            Text(post.text)
                .foregroundColor(.primary)
            
            if let url = post.imageURL {
                WebImage(url: url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            PostInteraction()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showCommentsSheet) {
            CommentsView(post: post)
        }
    }
    
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack {
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .foregroundColor(post.likedIDs.contains(userUID) ? .accentColor : .primary)
            }
            Text("\(post.likedIDs.count)")
            
            Button(action: dislikePost) {
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .foregroundColor(post.dislikedIDs.contains(userUID) ? .accentColor : .primary)
            }
            Text("\(post.dislikedIDs.count)")
            
            Spacer()
            
            Button(action: { showCommentsSheet = true }) {
                Image(systemName: "text.bubble")
            }
        }
        .padding(.top, 8)
    }
    
    func likePost() {
        Task {
            guard let postID = post.id else { return }
            let docRef = Firestore.firestore().collection("Posts").document(postID)
            if post.likedIDs.contains(userUID) {
                try await docRef.updateData(["likedIDs": FieldValue.arrayRemove([userUID])])
            } else {
                try await docRef.updateData(["likedIDs": FieldValue.arrayUnion([userUID]), "dislikedIDs": FieldValue.arrayRemove([userUID])])
            }
            onUpdate(try! await docRef.getDocument().data(as: Post.self))
        }
    }
    
    func dislikePost() {
        Task {
            guard let postID = post.id else { return }
            let docRef = Firestore.firestore().collection("Posts").document(postID)
            if post.dislikedIDs.contains(userUID) {
                try await docRef.updateData(["dislikedIDs": FieldValue.arrayRemove([userUID])])
            } else {
                try await docRef.updateData(["dislikedIDs": FieldValue.arrayUnion([userUID]), "likedIDs": FieldValue.arrayRemove([userUID])])
            }
            onUpdate(try! await docRef.getDocument().data(as: Post.self))
        }
    }
    
    // MARK: - Delete Post Function
    func deletePost() {
        Task {
            guard let postID = post.id else { return }
            do {
                let docRef = Firestore.firestore().collection("Posts").document(postID)
                
                // Check if the post has an image and delete it from storage if it does
                if !post.imageReferenceID.isEmpty {
                    let storageRef = Storage.storage().reference().child("Post_Images").child(post.imageReferenceID)
                    try await storageRef.delete()
                }
                
                // Delete the post from Firestore
                try await docRef.delete()
                
                // Call onDelete to update UI
                onDelete()
            } catch {
                print("Error deleting post: \(error.localizedDescription)")
                // Here you might want to show an error to the user or handle it differently
            }
        }
    }
}

struct PostCardView_Previews: PreviewProvider {
    static var previews: some View {
        PostCardView(post: Post(text: "Sample Post", userName: "John Doe", userUID: "123", userProfileURL: URL(string: "https://example.com")!)) { _ in } onDelete: {}
    }
}
