//
//  ProfileView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    // MARK: My Profile Data
    @State private var myProfile: User?
    @State private var myPosts: [Post] = []
    
    // MARK: User Defaults Data
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("log_status") var logStatus: Bool = false
    
    // MARK: View Properties
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let myProfile {
                        ReusableProfileContent(user: myProfile)
                            .refreshable {
                                // MARK: Refresh User Data and Posts
                                self.myProfile = nil
                                self.myPosts = []
                                await fetchUserData()
                                await fetchMyPosts()
                            }
                        
                        // Posts Section
                        if !myPosts.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Posts")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ReusablePostsView(posts: $myPosts)
                                    .frame(height: 300) // Limit the height to avoid overwhelming the view
                            }
                        } else {
                            Text("No Posts Yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    } else {
                        ProgressView()
                            .tint(.primary)
                    }
                }
            }
            .navigationTitle("My profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .tint(.primary)
                    }
                }
            }
            .background(Color(UIColor.systemBackground)) // Ensure the entire view matches system theme
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) { }
        .task {
            // Initial fetch if myProfile or myPosts are empty
            if myProfile == nil {
                await fetchUserData()
            }
            if myPosts.isEmpty {
                await fetchMyPosts()
            }
        }
    }
    
    // MARK: Fetching User Data
    func fetchUserData() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            let user = try await Firestore.firestore()
                .collection("Users")
                .document(userUID)
                .getDocument(as: User.self)
            await MainActor.run {
                myProfile = user
            }
        } catch {
            print("Error fetching user data: \(error)")
        }
    }
    
    // MARK: Fetching My Posts
    func fetchMyPosts() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            let query = Firestore.firestore().collection("Posts")
                .whereField("userUID", isEqualTo: userUID)
                .order(by: "publishedDate", descending: true)
                .limit(to: 10) // Limit to 10 posts for performance
            
            let snapshot = try await query.getDocuments()
            let posts = try snapshot.documents.compactMap { try $0.data(as: Post.self) }
            await MainActor.run {
                myPosts = posts
            }
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
    
    // MARK: Logging User Out
    func logOutUser() {
        do {
            try Auth.auth().signOut()
            userUID = ""
            userName = ""
            profileURL = nil
            logStatus = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: Deleting User Entire Account
    func deleteAccount() {
        isLoading = true
        Task {
            do {
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                // 1) Delete Profile Image from Storage
                let ref = Storage.storage().reference()
                    .child("Profile_Images")
                    .child(userUID)
                try await ref.delete()
                
                // 2) Delete Firestore User Document
                try await Firestore.firestore()
                    .collection("Users")
                    .document(userUID)
                    .delete()
                
                // 3) Delete Auth Account
                try await Auth.auth().currentUser?.delete()
                
                // 4) Update UI for logged out state
                self.userUID = ""
                userName = ""
                profileURL = nil
                logStatus = false
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: Setting Error
    func setError(_ error: Error) async {
        await MainActor.run {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        ProfileView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}
