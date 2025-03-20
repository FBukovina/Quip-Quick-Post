//
//  EditProfileView.swift
//  opensocial
//
//  Created by Filip Bukovina on 24.01.2025.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct EditProfileView: View {
    // MARK: - User Data
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var userBio: String = ""
    @State private var userBioLink: String = ""
    @State private var userProfileURL: String = "" // Proměnná pro URL obrázku

    // MARK: - UI States
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false

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
                Section(header: Text("Profile Picture URL")) {
                    TextField("Enter image URL", text: $userProfileURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
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
                // Načtení URL obrázku, pokud existuje
                if let profileURLString = data["userProfileURL"] as? String {
                    await MainActor.run {
                        userProfileURL = profileURLString
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
                var newData: [String: Any] = [
                    "username": username,
                    "displayName": displayName,
                    "userBio": userBio.trimmingCharacters(in: .whitespacesAndNewlines),
                    "userBioLink": userBioLink
                ]
                
                // Pokud je URL vyplněná, použij ji
                if !userProfileURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Ukládáme pod klíčem "userProfileURL", aby to odpovídalo načítání
                    newData["userProfileURL"] = userProfileURL
                    print("Using profile image URL provided by user: \(userProfileURL)")
                }
                
                // Kontrola, zda userBio není prázdný či pouze bílé znaky
                if newData["userBio"] as? String == "" {
                    print("User bio is empty or just whitespace, not updating userBio.")
                }
                
                try await Firestore.firestore().collection("Users").document(userUID).setData(newData, merge: true)
                print("Profile saved successfully")
                
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
