//
//  LoginView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore
import FirebaseAuth

struct LoginView: View {
    // MARK: - User Details
    @State var emailID: String = ""
    @State var password: String = ""
    
    // MARK: - View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    // MARK: - User Defaults
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("log_status") var logStatus: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Hello again!")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .hAlign(.leading)
            
            Text("Welcome Back,\nWe're happy that you are back.")
                .font(.title3)
                .foregroundColor(.secondary)
                .hAlign(.leading)
            
            VStack(spacing: 12) {
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, Color.gray.opacity(0.5))
                    .padding(.top, 25)
                    .foregroundColor(.primary)
                    .background(Color(UIColor.systemBackground))
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .border(1, Color.gray.opacity(0.5))
                    .foregroundColor(.primary)
                    .background(Color(UIColor.systemBackground))
                
                Button("Reset password?", action: self.resetPassword) // Corrected to self.resetPassword
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                    .hAlign(.trailing)
                
                Button(action: self.loginUser) { // Corrected to self.loginUser
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
            
            HStack {
                Text("Ready to Quip?")
                    .foregroundColor(.secondary)
                
                Button("Register Now") {
                    createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .background(Color(UIColor.systemBackground))
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    // MARK: - Login User
    func loginUser() {
        isLoading = true
        closeKeyboard()
        
        Task {
            do {
                // Sign in using Firebase Auth
                let _ = try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                
                // After successful login, fetch user data from Firestore
                try await fetchUser()
                
                // If fetchUser() succeeds, set isLoading to false
                await MainActor.run {
                    isLoading = false
                }
                
            } catch {
                // If error, stop loading + show error
                await MainActor.run {
                    isLoading = false
                }
                await setError(error)
            }
        }
    }
    
    // MARK: - Fetch User
    func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("Users").document(userID)
        let document = try await docRef.getDocument()
        
        if let data = document.data() {
            print("Fetched user data: \(data)")
        } else {
            // If data doesn't exist, create new default user data
            print("No data found for user ID: \(userID). Adding user data...")
            try await addUserToFirestore(userID: userID, email: emailID)
        }

        // Decode Firestore data directly into the User model
        do {
            let user = try document.data(as: User.self)
            // When successful, update user defaults & set logStatus = true
            await MainActor.run {
                userUID = userID
                userNameStored = user.username
                profileURL = user.userProfileURL
                logStatus = true
            }
        } catch {
            print("Decoding error: \(error)")
            throw NSError(domain: "", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Data decoding failed."
            ])
        }
    }
    
    // MARK: - Add User Data to Firestore
    func addUserToFirestore(userID: String, email: String) async throws {
        let userData: [String: Any] = [
            "username": "New User",
            "userBio": "Write your bio here.",
            "userBioLink": "",
            "userUID": userID,
            "userEmail": email,
            "userProfileURL": ""
        ]
        
        try await Firestore.firestore().collection("Users").document(userID).setData(userData)
        print("User added to Firestore!")
    }
    
    // MARK: - Reset Password
    func resetPassword() {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: - Handle Errors
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            print("Error: \(error)")
            showError.toggle()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        LoginView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}
