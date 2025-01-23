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
    
    /// Callbacks for parent to update or remove the post in the UI
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    
    // The current user's UID for like/dislike logic
    @AppStorage("user_UID") private var userUID: String = ""
    
    // Realtime Firestore listener
    @State private var docListener: ListenerRegistration?
    
    // Controls showing the comments sheet
    @State private var showCommentsSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Top: User avatar + name + optional delete menu
            HStack(alignment: .top, spacing: 12) {
                // Profile image
                WebImage(url: post.userProfileURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(post.userName)
                        .font(.callout)
                        .fontWeight(.semibold)
                    
                    Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // If this user is the post owner, show a delete button
                if post.userUID == userUID {
                    Menu {
                        Button("Delete Post", role: .destructive) {
                            deletePost()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .rotationEffect(.degrees(-90))
                            .foregroundColor(.black)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .offset(x: 8)
                }
            }
            
            // MARK: Post Text
            Text(post.text)
                .textSelection(.enabled)
                .padding(.vertical, 8)
            
            // MARK: Post Image (if any)
            if let url = post.imageURL {
                GeometryReader { geo in
                    WebImage(url: url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(height: 200)
            }
            
            // MARK: Like/Dislike + Comment
            PostInteraction()
        }
        .padding(12)
        
        // Listen to Firestore changes in real time
        .onAppear {
            if docListener == nil, let postID = post.id {
                docListener = Firestore.firestore()
                    .collection("Posts")
                    .document(postID)
                    .addSnapshotListener { snapshot, error in
                        if let snapshot {
                            if snapshot.exists {
                                // Document updated
                                if let updatedPost = try? snapshot.data(as: Post.self) {
                                    onUpdate(updatedPost)
                                }
                            } else {
                                // Document deleted
                                onDelete()
                            }
                        }
                    }
            }
        }
        .onDisappear {
            // Remove the snapshot listener to save resources
            docListener?.remove()
            docListener = nil
        }
        // Show Comments in a sheet
        .sheet(isPresented: $showCommentsSheet) {
            CommentsView(post: post)
        }
    }
    
    // MARK: UI for like/dislike + comments
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack(spacing: 6) {
            // Like
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID)
                       ? "hand.thumbsup.fill"
                       : "hand.thumbsup")
            }
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Dislike
            Button(action: dislikePost) {
                Image(systemName: post.dislikedIDs.contains(userUID)
                       ? "hand.thumbsdown.fill"
                       : "hand.thumbsdown")
            }
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Comment button
            Button {
                // Opens CommentsView sheet
                showCommentsSheet = true
            } label: {
                Image(systemName: "text.bubble")
            }
        }
        .foregroundColor(.black)
        .padding(.top, 8)
    }
    
    // MARK: Like Post
    func likePost() {
        Task {
            guard let postID = post.id else { return }
            let docRef = Firestore.firestore().collection("Posts").document(postID)
            
            if post.likedIDs.contains(userUID) {
                try await docRef.updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                // Add to liked, remove from disliked if present
                try await docRef.updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    // MARK: Dislike Post
    func dislikePost() {
        Task {
            guard let postID = post.id else { return }
            let docRef = Firestore.firestore().collection("Posts").document(postID)
            
            if post.dislikedIDs.contains(userUID) {
                try await docRef.updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                // Add to disliked, remove from liked if present
                try await docRef.updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    // MARK: Delete Post
    func deletePost() {
        Task {
            do {
                // If there's an image, remove it from Storage
                if !post.imageReferenceID.isEmpty {
                    let ref = Storage.storage()
                        .reference()
                        .child("Post_Images")
                        .child(post.imageReferenceID)
                    try await ref.delete()
                }
                
                // Remove the doc from Firestore
                guard let postID = post.id else { return }
                try await Firestore.firestore()
                    .collection("Posts")
                    .document(postID)
                    .delete()
                
            } catch {
                print("Delete error: \(error.localizedDescription)")
            }
        }
    }
}
