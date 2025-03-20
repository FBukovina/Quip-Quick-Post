//
//  CommentsView.swift
//  opensocial
//
//  Created by Filip Bukovina on 20.01.2025.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

// Comment model with new fields for like/dislike counts, reply reference, and reactions.
struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var userUID: String
    var userName: String
    var publishedDate: Date
    var likes: Int?      // Like count
    var dislikes: Int?   // Dislike count
    var replyToUser: String? // If this comment is a reply, this holds the name of the original comment's author.
    var reactions: [String: String]? // Mapping from userUID to reaction ('like' or 'dislike')
}

struct CommentsView: View {
    let post: Post  // The post for which we're displaying comments
    
    @State private var comments: [Comment] = []
    @State private var newComment: String = ""
    
    // Removed reply functionality
    // @State private var replyCommentID: String? = nil
    // @State private var replyText: String = ""
    
    // Get user info from AppStorage
    @AppStorage("user_UID") private var userUID: String = ""
    @AppStorage("user_name") private var userName: String = ""
    
    // Firestore listener
    @State private var listener: ListenerRegistration?
    
    var body: some View {
        NavigationView {
            VStack {
                if comments.isEmpty {
                    Text("No comments yet.")
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                } else {
                    List {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                // Header: User name and reply indicator (if available)
                                HStack {
                                    Text(comment.userName)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    if let replyTo = comment.replyToUser {
                                        Text("(Reply to \(replyTo))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Comment text and timestamp
                                Text(comment.text)
                                    .foregroundColor(.primary)
                                
                                Text(comment.publishedDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Action buttons: Reaction buttons and Delete button
                                HStack {
                                    // Reactions group: Like and Dislike buttons
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            toggleLikeReaction(comment: comment)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: (comment.reactions?[userUID] == "like") ? "hand.thumbsup.fill" : "hand.thumbsup")
                                                Text("\(comment.likes ?? 0)")
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .contentShape(Rectangle())
                                        
                                        Button(action: {
                                            toggleDislikeReaction(comment: comment)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: (comment.reactions?[userUID] == "dislike") ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                                Text("\(comment.dislikes ?? 0)")
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .contentShape(Rectangle())
                                    }
                                    
                                    Spacer()
                                    
                                    // Delete button (only if current user is the author)
                                    if comment.userUID == userUID {
                                        Button(action: {
                                            deleteComment(comment: comment)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .background(Color(UIColor.systemBackground))
                }
                
                // Add a new comment at the bottom
                HStack {
                    TextField("Write a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.primary)
                    
                    Button("Send") {
                        addComment()
                    }
                    .disabled(newComment.isEmpty)
                    .foregroundColor(.primary)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Comments")
            .background(Color(UIColor.systemBackground))
            .onAppear {
                fetchComments()
            }
            .onDisappear {
                listener?.remove()
                listener = nil
            }
        }
    }
    
    // MARK: - Fetch Comments in Real Time
    func fetchComments() {
        guard let postID = post.id else { return }
        listener = Firestore.firestore()
            .collection("Posts")
            .document(postID)
            .collection("Comments")
            .order(by: "publishedDate", descending: false)
            .addSnapshotListener { snapshot, error in
                if let docs = snapshot?.documents {
                    do {
                        comments = try docs.compactMap { doc in
                            try doc.data(as: Comment.self)
                        }
                    } catch {
                        print("Error decoding comments: \(error)")
                    }
                }
            }
    }
    
    // MARK: - Add a New Comment
    func addComment() {
        guard let postID = post.id else { return }
        
        let commentData: [String: Any] = [
            "text": newComment,
            "userUID": userUID,
            "userName": userName,
            "publishedDate": Date()
        ]
        
        Firestore.firestore()
            .collection("Posts")
            .document(postID)
            .collection("Comments")
            .addDocument(data: commentData) { error in
                if let error = error {
                    print("Error adding comment: \(error.localizedDescription)")
                } else {
                    newComment = ""
                }
            }
    }
    
    // MARK: - Toggle Like Reaction
    func toggleLikeReaction(comment: Comment) {
        guard let postID = post.id, let commentID = comment.id else { return }
        let commentRef = Firestore.firestore()
            .collection("Posts")
            .document(postID)
            .collection("Comments")
            .document(commentID)
        
        Firestore.firestore().runTransaction({ transaction, errorPointer in
            let commentDocument: DocumentSnapshot
            do {
                try commentDocument = transaction.getDocument(commentRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            var currentLikes = commentDocument.data()?["likes"] as? Int ?? 0
            var currentDislikes = commentDocument.data()?["dislikes"] as? Int ?? 0
            var reactions = commentDocument.data()?["reactions"] as? [String: String] ?? [:]
            
            let currentReaction = reactions[userUID]
            
            if currentReaction == "like" {
                // Undo like
                reactions[userUID] = nil
                currentLikes = max(currentLikes - 1, 0)
            } else if currentReaction == "dislike" {
                // Change reaction from dislike to like
                reactions[userUID] = "like"
                currentDislikes = max(currentDislikes - 1, 0)
                currentLikes += 1
            } else {
                // Add like reaction
                reactions[userUID] = "like"
                currentLikes += 1
            }
            
            transaction.updateData([
                "likes": currentLikes,
                "dislikes": currentDislikes,
                "reactions": reactions
            ], forDocument: commentRef)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Error toggling like reaction: \(error)")
            }
        }
    }
    
    // MARK: - Toggle Dislike Reaction
    func toggleDislikeReaction(comment: Comment) {
        guard let postID = post.id, let commentID = comment.id else { return }
        let commentRef = Firestore.firestore()
            .collection("Posts")
            .document(postID)
            .collection("Comments")
            .document(commentID)
        
        Firestore.firestore().runTransaction({ transaction, errorPointer in
            let commentDocument: DocumentSnapshot
            do {
                try commentDocument = transaction.getDocument(commentRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            var currentLikes = commentDocument.data()?["likes"] as? Int ?? 0
            var currentDislikes = commentDocument.data()?["dislikes"] as? Int ?? 0
            var reactions = commentDocument.data()?["reactions"] as? [String: String] ?? [:]
            
            let currentReaction = reactions[userUID]
            
            if currentReaction == "dislike" {
                // Undo dislike
                reactions[userUID] = nil
                currentDislikes = max(currentDislikes - 1, 0)
            } else if currentReaction == "like" {
                // Change reaction from like to dislike
                reactions[userUID] = "dislike"
                currentLikes = max(currentLikes - 1, 0)
                currentDislikes += 1
            } else {
                // Add dislike reaction
                reactions[userUID] = "dislike"
                currentDislikes += 1
            }
            
            transaction.updateData([
                "likes": currentLikes,
                "dislikes": currentDislikes,
                "reactions": reactions
            ], forDocument: commentRef)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Error toggling dislike reaction: \(error)")
            }
        }
    }
    
    // MARK: - Delete a Comment
    func deleteComment(comment: Comment) {
        guard let postID = post.id, let commentID = comment.id else { return }
        Firestore.firestore()
            .collection("Posts")
            .document(postID)
            .collection("Comments")
            .document(commentID)
            .delete { error in
                if let error = error {
                    print("Error deleting comment: \(error.localizedDescription)")
                }
            }
    }
}

struct CommentsView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyPost = Post(id: "dummyPostId", text: "Dummy Post", publishedDate: Date(), userName: "Dummy User", userUID: "dummyUID", userProfileURL: URL(string: "https://example.com/dummy.png")!)
        CommentsView(post: dummyPost)
            .preferredColorScheme(.light)
            .previewDisplayName("CommentsView Preview")
    }
}
