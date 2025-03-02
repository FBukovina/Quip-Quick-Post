//
//  RegisterView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct RegisterView: View {
    // MARK: - User Details
    @State private var emailID: String = ""
    @State private var password: String = ""
    @State private var userName: String = ""
    @State private var userBio: String = ""
    @State private var userBioLink: String = ""
    @State private var userProfilePicData: Data?
    
    // MARK: - View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    // Dismiss Keyboard
    @FocusState private var isFocused: Bool
    
    // MARK: - User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""

    var body: some View {
        VStack(spacing: 10) {
            Text("Let's Register\nAccount!")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary) // Adapts to dark/light mode
            
            Text("Hello, switch to Quip.")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.secondary) // Better contrast in dark mode
            
            // If you have many fields, make them scrollable
            ScrollView(.vertical, showsIndicators: false) {
                HelperView()
            }
            .padding(.top, 10)
            .background(Color(UIColor.systemBackground)) // ScrollView background matches theme
            
            HStack {
                Text("Do you have an account?")
                    .foregroundColor(.gray)
                
                Button("Log in here.") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.primary) // Better visibility in dark mode
            }
            .font(.callout)
        }
        .padding(15)
        .background(Color(UIColor.systemBackground)) // Ensure entire view matches system theme
        .overlay {
            LoadingView(show: $isLoading)
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { _, newValue in
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {
                            return
                        }
                        await MainActor.run {
                            userProfilePicData = imageData
                        }
                    } catch {
                        print("Failed to load image data: \(error)")
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    // MARK: - The UI for input fields
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12) {
            Button {
                showImagePicker.toggle()
            } label: {
                if let data = userProfilePicData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            TextField("Username", text: $userName)
                .textContentType(.username)
                .border(1, Color.gray.opacity(0.5))
                .padding(.top, 25)
                .foregroundColor(.primary)
                .background(Color(UIColor.systemBackground))
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, Color.gray.opacity(0.5))
                .padding(.top, 25)
                .foregroundColor(.primary)
                .background(Color(UIColor.systemBackground))
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .border(1, Color.gray.opacity(0.5))
                .padding(.top, 25)
                .foregroundColor(.primary)
                .background(Color(UIColor.systemBackground))
            
            // If you don't truly require a bio, comment this out
            TextField("About You (Optional)", text: $userBio, axis: .vertical)
                .border(1, Color.gray.opacity(0.5))
                .padding(.top, 25)
                .foregroundColor(.primary)
                .background(Color(UIColor.systemBackground))
            
            // If you don't require a link, keep it optional
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.URL)
                .border(1, Color.gray.opacity(0.5))
                .padding(.top, 25)
                .foregroundColor(.primary)
                .background(Color(UIColor.systemBackground))
            
            Button(action: registerUser) {
                Text("Sign up")
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            // Make sure the button is not accidentally disabled
            // If you require a profile pic & certain fields, re-add them
            .disabled(emailID.isEmpty || password.isEmpty || userName.isEmpty)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Register Logic
    func registerUser() {
        print("Register button tapped")
        isFocused = false
        isLoading = true
        
        Task {
            do {
                // 1) Create user in Firebase Auth
                print("Creating user with email: \(emailID)")
                let authResult = try await Auth.auth().createUser(withEmail: emailID, password: password)
                let currentUID = authResult.user.uid
                print("User created with UID: \(currentUID)")
                
                // 2) If a profile pic is selected, upload to Storage
                var photoURL: URL? = nil
                if let data = userProfilePicData {
                    print("Uploading profile picture...")
                    let storageRef = Storage.storage().reference()
                        .child("Profile_Images")
                        .child(currentUID)
                    
                    // putDataAsync
                    _ = try await storageRef.putDataAsync(data)
                    photoURL = try await storageRef.downloadURL()
                    print("Profile image uploaded, URL: \(photoURL?.absoluteString ?? "")")
                }
                
                // 3) Prepare the data for Firestore
                var userData: [String: Any] = [
                    "username": userName,
                    "userUID": currentUID,
                    "userEmail": emailID
                ]
                
                // If you have optional fields
                if !userBio.isEmpty {
                    userData["userBio"] = userBio
                }
                if !userBioLink.isEmpty {
                    userData["userBioLink"] = userBioLink
                }
                if let photoURL {
                    userData["userProfileURL"] = photoURL.absoluteString
                }
                
                // 4) Write to Firestore
                print("Saving user data to Firestore...")
                try await Firestore.firestore().collection("Users")
                    .document(currentUID)
                    .setData(userData)
                print("User data saved to Firestore.")
                
                // 5) Update local @AppStorage
                await MainActor.run {
                    userUID = currentUID
                    userNameStored = userName
                    if let photoURL { profileURL = photoURL }
                    logStatus = true
                    isLoading = false
                }
                
                // Optionally dismiss if you want
                // await MainActor.run { dismiss() }
                
            } catch {
                print("Error during registration: \(error.localizedDescription)")
                await setError(error)
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


struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        RegisterView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}
