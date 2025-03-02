//
//  EditProfileView.swift
//  opensocial
//
//  Created by Filip Bukovina on 24.01.2025.
//

import SwiftUI
import Firebase
import FirebaseStorage
import PhotosUI

struct EditProfileView: View {
    // MARK: - User Data
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var userBio: String = ""
    @State private var userBioLink: String = ""
    @State private var profileImageLink: String = "" // Nová proměnná pro URL obrázku
    @State private var profileImage: UIImage?
    @State private var imageData: Data?
    
    // MARK: - UI States
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    
    // MARK: - Navigation
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                    TextField("Display Name", text: $displayName)
                    TextField("Bio", text: $userBio)
                    TextField("Bio Link", text: $userBioLink)
                }
                
                // Sekce pro zadání URL profilového obrázku
                Section(header: Text("Profile Picture URL (optional)")) {
                    TextField("Enter image URL", text: $profileImageLink)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Profile Picture")) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 5)
                            .padding(.bottom)
                        
                        Button(action: {
                            showImagePicker.toggle()
                        }) {
                            Text("Change Profile Picture")
                        }
                    } else {
                        Button(action: {
                            showImagePicker.toggle()
                        }) {
                            HStack {
                                Text("Add Profile Picture")
                                Image(systemName: "camera")
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: saveProfile) {
                        Text("Save")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                        self.imageData = data
                    }
                }
            }
        }
        .overlay {
            if isLoading {
                LoadingView(show: .constant(true))
            }
        }
        .alert(errorMessage, isPresented: $showError) {}
        .task {
            await loadUserProfile()
        }
    }
    
    // MARK: - Load User Profile Data
    func loadUserProfile() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await Firestore.firestore().collection("Users").document(userUID).getDocument()
            if let data = doc.data() {
                await MainActor.run {
                    username = data["username"] as? String ?? ""
                    displayName = data["displayName"] as? String ?? ""
                    userBio = data["userBio"] as? String ?? ""
                    userBioLink = data["userBioLink"] as? String ?? ""
                }
                
                // Asynchronní načtení obrázku z URL
                if let profileURLString = data["profileURL"] as? String {
                    await MainActor.run {
                        profileImageLink = profileURLString
                    }
                    if let url = URL(string: profileURLString) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                await MainActor.run {
                                    profileImage = image
                                }
                            }
                        } catch {
                            print("Error loading image from URL: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } catch {
            print("Error loading user profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Save Profile Changes
    func saveProfile() {
        isLoading = true
        guard let userUID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not found"
            showError = true
            isLoading = false
            return
        }
        
        Task {
            do {
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                
                var newData: [String: Any] = [
                    "username": username,
                    "displayName": displayName,
                    "userBio": userBio.trimmingCharacters(in: .whitespacesAndNewlines),
                    "userBioLink": userBioLink
                ]
                
                // Pokud je URL vyplněná, použij ji místo nahrávání obrázku
                if !profileImageLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    newData["profileURL"] = profileImageLink
                    print("Using profile image URL provided by user: \(profileImageLink)")
                } else if let imageData = imageData {
                    print("Attempting to upload profile image")
                    let _ = try await storageRef.putDataAsync(imageData)
                    let downloadURL = try await storageRef.downloadURL()
                    let urlString = downloadURL.absoluteString
                    print("Image uploaded, URL: \(urlString)")
                    newData["profileURL"] = urlString
                }
                
                // Kontrola, zda userBio není prázdný či pouze bílé znaky
                if newData["userBio"] as? String == "" {
                    print("User bio is empty or just whitespace, not updating userBio.")
                } else {
                    try await Firestore.firestore().collection("Users").document(userUID).setData(newData, merge: true)
                    print("Profile saved successfully")
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving profile: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
    }
}
