//
//  ReusablePostsView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import FirebaseFirestore

struct ReusablePostsView: View {
    @Binding var posts: [Post]
    @State private var isFetching: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 15) {
                if isFetching {
                    ProgressView()
                        .padding(.top, 30)
                        .tint(.primary)
                } else {
                    if posts.isEmpty {
                        Text("No Posts Found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 30)
                    } else {
                        ForEach(posts) { post in
                            PostCardView(post: post) { updatedPost in
                                if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                                    posts[index] = updatedPost
                                }
                            } onDelete: {
                                posts.removeAll { $0.id == post.id }
                            }
                        }
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            isFetching = true
            posts = []
            Task {
                await fetchPosts()
            }
        }
        .onAppear {
            if posts.isEmpty {
                Task {
                    await fetchPosts()
                }
            }
        }
    }
    
    func fetchPosts() async {
        do {
            let query = Firestore.firestore().collection("Posts")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            let snapshot = try await query.getDocuments()
            let fetchedPosts = try snapshot.documents.compactMap { try $0.data(as: Post.self) }
            
            await MainActor.run {
                self.posts = fetchedPosts
                self.isFetching = false
            }
        } catch {
            print("Error fetching posts: \(error.localizedDescription)")
            await MainActor.run {
                self.isFetching = false
            }
        }
    }
}

struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ReusablePostsView(posts: .constant([]))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        ReusablePostsView(posts: .constant([]))
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}
