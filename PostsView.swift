//
//  PostsView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct post: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String        // Example field for post text
    var userName: String    // Example field for user name
    var userUID: String     // Example field for user UID
    // Add any other fields you store in Firestore (e.g. imageURL, userProfileURL, timestamp, etc.)
}

struct PostsView: View {
    @State private var recentsPosts: [Post] = []
    @State private var createNewPost: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if recentsPosts.isEmpty {
                    Text("No posts yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                } else {
                    // Display each post
                    ForEach(recentsPosts) { post in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.text)
                                .font(.body)
                                .foregroundColor(.primary)

                            Text("By \(post.userName)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Divider()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Home")
            .overlay(alignment: .bottomTrailing) {
                // Plus button to create a new post
                Button {
                    createNewPost.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(13)
                        .background(.black, in: Circle())
                }
                .padding(15)
            }
        }
        // Fetch posts whenever this view appears
        .onAppear {
            fetchPosts()
        }
        // Show the CreateNewPost screen as a full screen cover
        .fullScreenCover(isPresented: $createNewPost) {
            CreateNewPost { post in
                // Insert the newly created post at the top
                recentsPosts.insert(post, at: 0)
            }
        }
    }

    // MARK: - Fetch Posts from Firestore
    func fetchPosts() {
        Firestore.firestore().collection("Posts")
            // .order(by: "timestamp", descending: true) // Uncomment if you store a timestamp
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("No documents in 'Posts' collection.")
                    return
                }
                do {
                    // Attempt to decode each document into a Post
                    let fetchedPosts = try documents.map { doc in
                        try doc.data(as: Post.self)
                    }
                    // Update our local array
                    recentsPosts = fetchedPosts
                } catch {
                    print("Error decoding posts: \(error)")
                }
            }
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}
