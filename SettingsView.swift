//
//  SettingsView.swift
//  opensocial
//
//  Created by Filip Bukovina on 20.01.2025.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    
    // Example version/sync info
    let appVersion = "0.1.2(1)"
    
    // MARK: - AppStorage for user session
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - opensocial+
                Section(header: Text("opensocial+")) {
                    NavigationLink(destination: Text("Detail View")) {
                        Label("Manage your subscription", systemImage: "plus")
                    }
                }
                
                // MARK: - Account
                Section(header: Text("ACCOUNT")) {
                    // Log Out Button
                    Button(action: logOutUser) {
                        Label("Log out", systemImage: "person.slash")
                    }
                    
                    // Get verified button
                    Button(action: getVerified) {
                        Label("Get verified", systemImage: "person.badge.shield.checkmark")
                    }
                }
                
                // MARK: - Help Center Section
                Section(header: Text("HELP CENTER")) {
                    NavigationLink(destination: Text("message me on feedback@bukovinafilip.com")) {
                        Label("Do you have a question?", systemImage: "questionmark.circle")
                    }
                    NavigationLink(destination: Text("Detail View")) {
                        Label("Contact me", systemImage: "envelope")
                    }
                    NavigationLink(destination: Text("Not available in this version.")) {
                        Label("Rate opensocial", systemImage: "star")
                    }
                   
                    NavigationLink(destination: Text("Coming soon...")) {
                        Label("Changelog", systemImage: "sparkles")
                    }
                   
                }
                
                // MARK: - More Section
                Section(header: Text("MORE")) {
                    NavigationLink(destination: Text("Visit bukovinafilip.com/opensocial")) {
                        Label("About opensocial", systemImage: "info.circle")
                    }
                    NavigationLink(destination: Text("Not available during development.")) {
                        Label("Terms of service", systemImage: "doc.text")
                    }
                    NavigationLink(destination: Text("Detail View")) {
                        Label("Zásady ochrany osobních údajů", systemImage: "hand.raised")
                    }
                    NavigationLink(destination: Text("Not available during development.")) {
                        Label("Share opensocial", systemImage: "square.and.arrow.up")
                    }
                }
                // MARK: - Account
                Section(header: Text("Danger Zone")) {
                    // Delete Account Button
                    Button(action: deleteAccount) {
                        Label("Delete account", systemImage: "person.badge.minus")
                    }
                }
                
                // MARK: - Footer (Version Info)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version: \(appVersion)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                }
            }
        }
    }
    
    // MARK: - Log Out
    func logOutUser(){
        do {
            try Auth.auth().signOut()
            // Clear local user data
            userUID = ""
            userName = ""
            profileURL = nil
            logStatus = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get Verified
    func getVerified() {
        if let url = URL(string: "https://verify.didit.me/session/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3Mzc2MzczNzAsImV4cCI6MTczODI0MjE3MCwic2Vzc2lvbl9pZCI6ImFlMTA2NTFmLTA0NTEtNGNiOC05OWQyLTkwNDEwYTE4ZTM0YyJ9.Oyd2HmPiEy6Y-XYsXAfmSNjOsywjqncYPJ3Kx02FPuE") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() {
        Task {
            do {
                guard let user = Auth.auth().currentUser else { return }
                // Deleting the user from Firebase Auth
                try await user.delete()
                
                // Clear local user data
                userUID = ""
                userName = ""
                profileURL = nil
                logStatus = false
                print("Account deleted successfully.")
            } catch {
                print("Error deleting account: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
