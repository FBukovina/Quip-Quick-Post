//
//  CreateNewPost.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct CreateNewPost: View {
    // MARK: - Callback when a new post is successfully created
    var onPost: (Post) -> ()
    
    // MARK: - Post Properties
    @State private var postText: String = ""
    
    // Dynamické nastavení max počtu znaků na základě předplatného
    @AppStorage("isPremium") private var isPremium: Bool = false
    private var maxCharacters: Int {
        isPremium ? 2500 : 500
    }
    
    // MARK: - Stored User Data (via AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .black
    
    // MARK: - View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @FocusState private var showKeyboard: Bool
    @AppStorage("debug") var debug = false
    
    var body: some View {
        VStack {
            // Top bar with Post button
            HStack {
                Button(action: dismiss.callAsFunction) {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.primary)
                }
                .hAlign(.leading)
                
                Button(action: createPost) {
                    Text("Quip")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(selectedTheme.color, in: Capsule())
                }
                .disableWithOpacity(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
                    .background(Color(UIColor.systemBackground))
            }
            
            // Main scroll area for post text
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    // TextField for post text with character limit based on subscription
                    TextField("What's up?!", text: $postText, axis: .vertical)
                        .focused($showKeyboard)
                        .foregroundColor(.primary)
                        .onChange(of: postText) { newValue in
                            if newValue.count > maxCharacters {
                                postText = String(newValue.prefix(maxCharacters))
                            }
                        }
                }
                .padding(15)
            }
            .background(Color(UIColor.systemBackground))
            
            // Bottom bar with character counter and Done button
            HStack(spacing: 20) {
                // Circular character count indicator
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Text("\(maxCharacters - postText.count)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button("Done") {
                    showKeyboard = false
                }
                .opacity(showKeyboard ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: showKeyboard)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
                    .background(Color(UIColor.systemBackground))
            }
        }
        .vAlign(.top)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            // Automatically show keyboard when view appears
            showKeyboard = true
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
        if postText == "enable_debug_mode" {
            debug = true
        } else {
            isLoading = true
            showKeyboard = false
            
            Task {
                do {
                    // Ensure user profile is available
                    var useProfileURL = profileURL
                    if useProfileURL == nil {
                        useProfileURL = URL(string: "https://your-default-profile-url-here.com/default.jpg")
                    }
                    
                    guard let profileURL = useProfileURL else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing profile URL."])
                    }
                    
                    let post = Post(
                        text: postText,
                        userName: userName,
                        userUID: userUID,
                        userProfileURL: profileURL
                    )
                    try await createDocumentAtFirebase(post)
                } catch {
                    await setError(error)
                }
            }
        }
        
        func createDocumentAtFirebase(_ post: Post) async throws {
            let docRef = Firestore.firestore().collection("Posts").document()
            try await docRef.setData(from: post)
            
            isLoading = false
            var updatedPost = post
            updatedPost.id = docRef.documentID
            onPost(updatedPost)
            dismiss()
        }
        
        func setError(_ error: Error) async {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError.toggle()
                isLoading = false
                print("Error: \(errorMessage)")
            }
        }
    }
}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost { _ in }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        CreateNewPost { _ in }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}
