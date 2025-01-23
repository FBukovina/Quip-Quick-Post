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
            VStack {
                if let myProfile {
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // MARK: Refresh User Data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("My profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                       
                        // MARK: Navigate to Settings
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) { }
        .task {
            // Initial fetch if myProfile is nil
            if myProfile == nil {
                await fetchUserData()
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
        ContentView()
    }
}
