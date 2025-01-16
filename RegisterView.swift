import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct RegisterView: View {
    // MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    
    // MARK: View Properties
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    // For keyboard dismissal
    @FocusState private var isFocused: Bool
    
    // MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Let's Register\nAccount!")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Hello, switch to opensocial.")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                
                HelperView()
            }
            
            HStack {
                Text("Do you have an account?")
                    .foregroundColor(.gray)
                
                Button("Log in here.") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
        }
        .padding(15)
        .padding(.top, 15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { _, newValue in
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
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
    
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12) {
            Button(action: {
                showImagePicker.toggle()
            }) {
                if let userProfilePicData, let image = UIImage(data: userProfilePicData) {
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
                .border(Color.gray.opacity(0.5), width: 2)
                .focused($isFocused)
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(Color.gray.opacity(0.5), width: 2)
                .focused($isFocused)
            
            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .border(Color.gray.opacity(0.5), width: 2)
                .focused($isFocused)
            
            TextField("About You", text: $userBio, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.none)
                .border(Color.gray.opacity(0.5), width: 2)
                .focused($isFocused)
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.URL)
                .border(Color.gray.opacity(0.5), width: 2)
                .focused($isFocused)
            
            Button(action: registerUser) {
                Text("Sign up")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
            }
            .disabled(userName.isEmpty || userBio.isEmpty || emailID.isEmpty || password.isEmpty || userProfilePicData == nil)
            .padding(.top, 10)
        }
    }
    
    struct LoadingView: View {
        @Binding var show: Bool
        
        var body: some View {
            if show {
                ZStack {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: Register User Logic
    func registerUser() {
        isFocused = false // Close keyboard
        isLoading = true
        Task {
            do {
                // Registration logic here...
            } catch {
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
