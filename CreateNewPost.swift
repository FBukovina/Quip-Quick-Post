//
//  CreateNewPost.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage

struct CreateNewPost: View {
    // MARK: - Callback when a new post is successfully created
    var onPost: (Post) -> ()
    
    // MARK: - Post Properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    
    // MARK: - Stored User Data (via AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    // MARK: - View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    
    var body: some View {
        VStack {
            // Top bar with Cancel and Post buttons
            HStack {
                Menu {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                .hAlign(.leading)
                
                Button(action: createPost) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.black, in: Capsule())
                }
                .disableWithOpacity(postText.isEmpty)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            
            // Main scroll area for post text + optional image
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    TextField("What's up?!", text: $postText, axis: .vertical)
                        .focused($showKeyboard)
                    
                    // If there's an image, display it with a delete button
                    if let postImageData,
                       let image = UIImage(data: postImageData) {
                        GeometryReader { proxy in
                            let size = proxy.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut) {
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            
            Divider()
            
            // Bottom bar with photo picker and a Done button
            HStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("Done") {
                    showKeyboard = false
                }
                .opacity(showKeyboard ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: showKeyboard)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .vAlign(.top)
        
        // MARK: - Image Picker
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            if let newValue {
                Task {
                    // Load and compress the selected image
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: rawImageData),
                       let compressedImageData = image.jpegData(compressionQuality: 0.5) {
                        await MainActor.run {
                            postImageData = compressedImageData
                            photoItem = nil
                        }
                    }
                }
            }
        }
        
        // MARK: - Error Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
        
        // MARK: - Loading View
        .overlay {
            LoadingView(show: $isLoading)
        }
    }
    
    // MARK: - Post to Firebase
    func createPost() {
        isLoading = true
        showKeyboard = false
        
        Task {
            do {
                // Ensure user profile is available
                guard let profileURL = profileURL else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing profile URL."])
                }
                
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference()
                    .child("Post_Images")
                    .child(imageReferenceID)
                
                // If there's an image, upload it
                if let postImageData {
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    // Create a Post model with image
                    let post = Post(
                        text: postText,
                        imageURL: downloadURL,
                        imageReferenceID: imageReferenceID,
                        userName: userName,
                        userUID: userUID,
                        userProfileURL: profileURL
                    )
                    
                    // Save to Firestore
                    try await createDocumentAtFirebase(post)
                    
                } else {
                    // No image -> just post text
                    let post = Post(
                        text: postText,
                        userName: userName,
                        userUID: userUID,
                        userProfileURL: profileURL
                    )
                    // Save to Firestore
                    try await createDocumentAtFirebase(post)
                }
                
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: - Write the Post Document to Firestore
    func createDocumentAtFirebase(_ post: Post) async throws {
        let docRef = Firestore.firestore().collection("Posts").document()
        try docRef.setData(from: post) { error in
            if error == nil {
                // Post successfully stored
                isLoading = false
                var updatedPost = post
                updatedPost.id = docRef.documentID
                onPost(updatedPost)
                dismiss()
            } else {
                Task { await setError(error!) }
            }
        }
    }
    
    // MARK: - Handle Errors
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        }
    }
}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost { _ in }
    }
}
