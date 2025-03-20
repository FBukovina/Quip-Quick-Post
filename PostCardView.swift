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
    @State private var showEditPostSheet: Bool = false
    @State private var currentUserProfileURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Zobrazíme aktuální profilový obrázek načtený z Firestore
                if let url = currentUserProfileURL, !url.absoluteString.isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                } else {
                    // Pokud není nastavena, nezobrazíme nic
                    EmptyView()
                }
                
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
                        Button("Edit") {
                            showEditPostSheet = true
                        }
                        Button("Delete", role: .destructive) {
                            deletePost()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            
            // Zobrazujeme text příspěvku s automatickou detekcí odkazů
            LinkTextView(text: post.text)
            
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
        .sheet(isPresented: $showEditPostSheet) {
            EditPostView(post: post, onUpdate: onUpdate)
        }
        .onAppear {
            fetchCurrentUserProfileImage()
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
                try await docRef.updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
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
                try await docRef.updateData([
                    "dislikedIDs": FieldValue.arrayUnion([userUID]),
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
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
                if !post.imageReferenceID.isEmpty {
                    let storageRef = Storage.storage().reference().child("Post_Images").child(post.imageReferenceID)
                    try await storageRef.delete()
                }
                try await docRef.delete()
                onDelete()
            } catch {
                print("Error deleting post: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchCurrentUserProfileImage() {
        let userDoc = Firestore.firestore().collection("Users").document(post.userUID)
        userDoc.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let urlString = data["userProfileURL"] as? String,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                DispatchQueue.main.async {
                    currentUserProfileURL = url
                }
            } else {
                print("Error fetching current user profile image: \(error?.localizedDescription ?? "No data")")
                DispatchQueue.main.async {
                    currentUserProfileURL = nil
                }
            }
        }
    }
}

struct PostCardView_Previews: PreviewProvider {
    static var previews: some View {
        PostCardView(
            post: Post(
                id: "sampleId",
                text: "Sample Post with a link: https://www.example.com",
                imageURL: nil,
                imageReferenceID: "",
                publishedDate: Date(),
                likedIDs: [],
                dislikedIDs: [],
                userName: "John Doe",
                userUID: "123",
                userProfileURL: URL(string: "")!  // Prázdná URL simulující, že se má načíst z Firestore
            ),
            onUpdate: { _ in },
            onDelete: {}
        )
    }
}

// MARK: - LinkTextView
struct LinkTextView: UIViewRepresentable {
    var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = [.link]
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}

// MARK: - EditPostView
struct EditPostView: View {
    @Environment(\.dismiss) var dismiss
    var post: Post
    var onUpdate: (Post) -> Void
    @State private var editedText: String

    init(post: Post, onUpdate: @escaping (Post) -> Void) {
        self.post = post
        self.onUpdate = onUpdate
        _editedText = State(initialValue: post.text)
    }

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $editedText)
                    .padding()
                    .border(Color.gray, width: 1)
                Spacer()
            }
            .navigationTitle("Edit Post")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { updatePost() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    func updatePost() {
        Task {
            guard let postID = post.id else { return }
            let docRef = Firestore.firestore().collection("Posts").document(postID)
            do {
                try await docRef.updateData(["text": editedText])
                let updatedPost = try await docRef.getDocument().data(as: Post.self)
                onUpdate(updatedPost)
                dismiss()
            } catch {
                print("Error updating post: \(error.localizedDescription)")
            }
        }
    }
}
