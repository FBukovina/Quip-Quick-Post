//
//  SettingsView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI
import FirebaseAuth
import Gleap

struct SettingsView: View {
    
    let appVersion = "0.9.10"
    
    // MARK: - AppStorage for user session
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .black

    var body: some View {
        NavigationView {
            List {
                // MARK: - Quip+
                Section(header: Text("Premium").foregroundColor(.primary)) {
                    NavigationLink(destination: SubscriptionView()) {
                        Label("Manage your subscription", systemImage: "plus")
                            .foregroundColor(.primary)
                    }
                }
                
                // MARK: - CUSTOMISATION
                Section(header: Text("CUSTOMISATION").foregroundColor(.primary)) {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("Black").tag(Theme.black)
                        Text("Green").tag(Theme.green)
                        Text("Teal").tag(Theme.teal)
                        Text("Blue").tag(Theme.blue)
                        Text("Yellow").tag(Theme.yellow)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    // Změna app ikony byla odstraněna.
                }
                
                // MARK: - Account
                Section(header: Text("ACCOUNT").foregroundColor(.primary)) {
                    NavigationLink(destination: EditProfileView()) {
                        Label("Edit Profile", systemImage: "person.crop.circle")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: self.logOutUser) {
                        Label("Log out", systemImage: "person.slash")
                            .foregroundColor(.primary)
                    }
                }
                
                // MARK: - Help Center Section
                Section(header: Text("HELP CENTER").foregroundColor(.primary)) {
                    Button(action: {
                        Gleap.initialize(withToken: "7ujSDhBuTuLQYloDW4AI1zB4extS6wcK")
                        // Gleap.show() lze přidat, pokud je potřeba.
                    }) {
                        Label("Need help?", systemImage: "questionmark.circle")
                            .foregroundColor(.primary)
                    }
    
                    NavigationLink(destination: ChangelogView()) {
                        Label("Changelog", systemImage: "sparkles")
                            .foregroundColor(.primary)
                    }
                }
                
                // MARK: - More Section
                Section(header: Text("MORE").foregroundColor(.primary)) {
                    NavigationLink(destination: AboutQuip()) {
                        Label("About Quip", systemImage: "info.circle")
                            .foregroundColor(.primary)
                    }
                    
                    Link(destination: URL(string: "https://bukovinafilip.com/terms-of-service")!) {
                        Label("Terms of service", systemImage: "doc.text")
                            .foregroundColor(.primary)
                    }
                    
                    Link(destination: URL(string: "https://bukovinafilip.com/privacy-policy")!) {
                        Label("Privacy policy", systemImage: "hand.raised")
                            .foregroundColor(.primary)
                    }
                    
                    
                    ShareLink(item: URL(string: "https://apps.apple.com/app/id1234567890")!, subject: Text("Check out Quip!"), message: Text("I found this app, check it out!")) {
                        Label("Share Quip", systemImage: "square.and.arrow.up")
                            .foregroundColor(.primary)
                    }
                }
                
                // MARK: - Danger Zone
                Section(header: Text("Danger Zone").foregroundColor(.primary)) {
                    Button(action: self.deleteAccount) {
                        Label("Delete account", systemImage: "person.badge.minus")
                            .foregroundColor(.red)
                    }
                }
                
                // MARK: - Footer (Version Info)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version: \(appVersion)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                
                // New Footer with Quip Logo and Developer Info
                Section {
                    VStack(spacing: 8) {
                        Image("quipofficial")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 100)
                        Text("Developed by Filip Bukovina.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // MARK: - Log Out
    func logOutUser(){
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
    
    // MARK: - Delete Account
    func deleteAccount() {
        Task {
            do {
                guard let user = Auth.auth().currentUser else { return }
                try await user.delete()
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        SettingsView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}

struct AboutQuip: View {
    @AppStorage("debug") var debug = false
    
    var body: some View {
        if !debug {
            AboutWebView(url: URL(string: "http://quip.bukovinafilip.com")!)
        } else {
            UserDefaultsEditorView()
        }
    }
}

import WebKit

struct AboutWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
