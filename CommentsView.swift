//
//  CommentsView.swift
//  opensocial
//
//  Created by Filip Bukovina on 20.01.2025.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

// Comment model
struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var userUID: String
    var userName: String
    var publishedDate: Date
}

struct CommentsView: View {
    let post: Post  // The post for which we're displaying comments
    
    @State private var comments: [Comment] = []
    @State private var newComment: String = ""
    
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
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                } else {
                    List(comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.userName)
                                .fontWeight(.semibold)
                            
                            Text(comment.text)
                            
                            Text(comment.publishedDate.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                 ))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
                }
                
                // Add a new comment
                HStack {
                    TextField("Write a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        addComment()
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .onAppear {
                fetchComments()
            }
            .onDisappear {
                // Remove listener
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
                        comments = try docs.compactMap {
                            try $0.data(as: Comment.self)
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
                    // Clear the text field on success
                    newComment = ""
                }
            }
    }
}
