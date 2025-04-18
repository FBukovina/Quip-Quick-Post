//
//  RegisterView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    // MARK: - User Details
    @State private var emailID: String = ""
    @State private var password: String = ""
    @State private var userName: String = ""
    @State private var userBio: String = ""
    @State private var userBioLink: String = ""
    @State private var userProfileURL: String = "" // Místo nahrávání obrázku, zadáme URL

    // MARK: - View Properties
    @Environment(\.dismiss) private var dismiss
    // Odebrány stavy pro PhotosPicker a nahrávání obrázku:
    // @State private var userProfilePicData: Data?
    // @State private var showImagePicker: Bool = false
    // @State private var photoItem: PhotosPickerItem?
    
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
                .foregroundColor(.primary)
            
            Text("Hello, switch to Quip.")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.secondary)
            
            // Pokud máte více polí, můžete je umístit do ScrollView
            ScrollView(.vertical, showsIndicators: false) {
                HelperView()
            }
            .padding(.top, 10)
            .background(Color(UIColor.systemBackground))
            
            HStack {
                Text("Do you have an account?")
                    .foregroundColor(.gray)
                
                Button("Log in here.") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.primary)
            }
            .font(.callout)
        }
        .padding(15)
        .background(Color(UIColor.systemBackground))
        .overlay {
            LoadingView(show: $isLoading)
        }
        // Odebrán PhotosPicker, protože již nepracujeme s nahráváním obrázku.
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    // MARK: - The UI for input fields
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12) {
            // Přidána sekce pro zadání URL profilového obrázku
            TextField("Enter Profile Image URL (optional)", text: $userProfileURL)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5))
                )
                .padding(.top, 25)
            
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
            
            // Pokud nechcete bio, můžete to zakomentovat
            TextField("About You (Optional)", text: $userBio, axis: .vertical)
                .border(1, Color.gray.opacity(0.5))
                .padding(.top, 25)
                .foregroundColor(.primary)
                .background(Color(UIColor.systemBackground))
            
            // Pokud nechcete bio link, ponechte jako volitelné
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
            // Deaktivace tlačítka, pokud nejsou vyplněna pole
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
                // 1) Vytvoří uživatele ve Firebase Auth
                print("Creating user with email: \(emailID)")
                let authResult = try await Auth.auth().createUser(withEmail: emailID, password: password)
                let currentUID = authResult.user.uid
                print("User created with UID: \(currentUID)")
                
                // 2) Místo nahrávání obrázku použijeme zadanou URL
                var photoURL: URL? = nil
                if !userProfileURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let url = URL(string: userProfileURL) {
                    photoURL = url
                    print("Using provided profile image URL: \(userProfileURL)")
                }
                
                // 3) Připrav data pro Firestore
                var userData: [String: Any] = [
                    "username": userName,
                    "userUID": currentUID,
                    "userEmail": emailID
                ]
                
                if !userBio.isEmpty {
                    userData["userBio"] = userBio
                }
                if !userBioLink.isEmpty {
                    userData["userBioLink"] = userBioLink
                }
                if let photoURL = photoURL {
                    userData["userProfileURL"] = photoURL.absoluteString
                }
                
                // 4) Ulož data do Firestore
                print("Saving user data to Firestore...")
                try await Firestore.firestore().collection("Users")
                    .document(currentUID)
                    .setData(userData)
                print("User data saved to Firestore.")
                
                // 5) Aktualizuj lokální @AppStorage
                await MainActor.run {
                    userUID = currentUID
                    userNameStored = userName
                    if let photoURL = photoURL {
                        profileURL = photoURL
                    }
                    logStatus = true
                    isLoading = false
                }
                
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
