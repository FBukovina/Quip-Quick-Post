import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    
    let appVersion = "0.7(1)"
    
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
                    
                    NavigationLink(destination: AppIconSelectionView()) {
                        Label("Change App Icon", systemImage: "app.badge")
                            .foregroundColor(.primary)
                    }
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
                    NavigationLink(destination: Text("message me on feedback@bukovinafilip.com")) {
                        Label("Need help?", systemImage: "questionmark.circle")
                            .foregroundColor(.primary)
                    }
    
                    NavigationLink(destination:ChangelogView ()) {
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
                    NavigationLink(destination: Text("Not available during development.")) {
                        Label("Terms of service", systemImage: "doc.text")
                            .foregroundColor(.primary)
                    }
                    NavigationLink(destination: Text("Detail View")) {
                        Label("Zásady ochrany osobních údajů", systemImage: "hand.raised")
                            .foregroundColor(.primary)
                    }
                    NavigationLink(destination: Text("Not available in this version.")) {
                        Label("Rate Quip", systemImage: "star")
                            .foregroundColor(.primary)
                    }
                    NavigationLink(destination: Text("Not available during development.")) {
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
            AboutWebView(url: URL(string: "http://bukovinafilip.com/opensocial")!)
        } else {
            UserDefaultsEditorView()
        }
    }
}

import SwiftUI
import WebKit

struct AboutWebView: UIViewRepresentable {
    // 1
    let url: URL

    
    // 2
    func makeUIView(context: Context) -> WKWebView {

        return WKWebView()
    }
    
    // 3
    func updateUIView(_ webView: WKWebView, context: Context) {

        let request = URLRequest(url: url)
        webView.load(request)
    }
}

