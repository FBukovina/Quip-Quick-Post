//
//  PostsView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import Firebase

struct PostsView: View {
    @State private var posts: [Post] = []
    @State private var createNewPost: Bool = false
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .black // or YourModuleName.Theme if needed

    var body: some View {
        NavigationStack {
            ReusablePostsView(posts: $posts)
                .navigationTitle("Home")
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        createNewPost.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(13)
                            .background(selectedTheme.color, in: Circle())
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    }
                    .padding(15)
                }
        }
        .fullScreenCover(isPresented: $createNewPost) {
            CreateNewPost { newPost in
                posts.insert(newPost, at: 0)
            }
        }
        .onAppear {
            fetchPosts()
        }
    }
    
    func fetchPosts() {
        Firestore.firestore().collection("Posts")
            .order(by: "publishedDate", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents in 'Posts' collection.")
                    return
                }
                do {
                    let fetchedPosts = try documents.compactMap { doc -> Post? in
                        var post = try doc.data(as: Post.self)
                        post.id = doc.documentID
                        return post
                    }
                    DispatchQueue.main.async {
                        posts = fetchedPosts
                    }
                } catch {
                    print("Error decoding posts: \(error)")
                }
            }
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")

        PostsView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}
