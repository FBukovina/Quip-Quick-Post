//
//  ReusableProfileContent.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct ReusableProfileContent: View {
    var user: User // Assuming User is in the same module
    @State private var fetchedPosts: [Post] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 15) {
                HStack(spacing: 12){
                    WebImage(url: user.userProfileURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary) // Adapt to theme
                        
                        Text(user.userBio)
                            .font(.caption)
                            .foregroundColor(.secondary) // Adapt to theme
                            .lineLimit(3)
                        
                        // MARK: Displaying Bio Link, If Given While Signing Up Profile Page
                        if let bioLink = URL(string: user.userBioLink){
                            Link(user.userBioLink, destination: bioLink)
                                .font(.callout)
                                .tint(.blue)
                                .lineLimit(1)
                        }
                    }
                    .hAlign(.leading)
                }
                
                Text("Posts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary) // Change to .primary for theme adaptation
                    .hAlign(.leading)
                    .padding(.vertical,15)
            }
            .padding(15)
        }
        .onAppear {
            fetchPosts()
        }
        .refreshable {
            fetchedPosts = []
            fetchPosts()
        }
    }
    
    // MARK: - Fetch Posts
    func fetchPosts() {
        isLoading = true
        Firestore.firestore().collection("Posts")
            .whereField("userUID", isEqualTo: user.userUID)
            .order(by: "publishedDate", descending: true)
            .limit(to: 10) // Adjust limit as needed
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                do {
                    fetchedPosts = try snapshot?.documents.compactMap { document in
                        var post = try document.data(as: Post.self)
                        post.id = document.documentID
                        return post
                    } ?? []
                } catch {
                    print("Error decoding posts: \(error)")
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
    }
}

// MARK: - Preview
struct ReusableProfileContent_Previews: PreviewProvider {
    static var previews: some View {
        ReusableProfileContent(user: User(id: "1", username: "example", userBio: "Sample Bio", userBioLink: "example.com", userUID: "userUID1", userEmail: "example@example.com", userProfileURL: URL(string: "example.com")!))
    }
}

// Assuming User model is defined elsewhere. If not, uncomment the following:
/*
struct User: Codable {
    let id: String
    let username: String
    let userBio: String
    let userBioLink: String
    let userUID: String
    let userEmail: String
    let userProfileURL: URL
}
*/
