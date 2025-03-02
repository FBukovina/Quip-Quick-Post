//
//  AppIcon.swift
//  opensocial
//
//  Created by Filip Bukovina on 12.02.2025.
//


import SwiftUI

struct AppIcon: Identifiable {
    let id = UUID()
    /// Pokud je nil, znamená to výchozí (default) ikonu.
    let iconName: String?
    let displayName: String
    let previewImageName: String
}

struct AppIconSelectionView: View {
    // Aktuálně nastavená ikona (nil = default)
    @State private var selectedIconName: String? = UIApplication.shared.alternateIconName
    @State private var errorMessage: String?
    
    // Seznam dostupných ikon – uprav si názvy dle toho, jak je máš nastavené v Assets
    let availableAppIcons: [AppIcon] = [
        AppIcon(iconName: nil, displayName: "Default", previewImageName: "quipofficial"), AppIcon(iconName: "quipbeta", displayName: "Beta", previewImageName: "quipicon"),
        AppIcon(iconName: "legacyicon", displayName: "opensocial", previewImageName: "opensocialicon")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose your app icon")
                .font(.title)
                .bold()
                .padding(.top)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 20)]) {
                    ForEach(availableAppIcons) { icon in
                        VStack {
                            Image(icon.previewImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIconName == icon.iconName ? Color.blue : Color.clear, lineWidth: 3)
                                )
                            Text(icon.displayName)
                                .font(.caption)
                        }
                        .padding()
                        .onTapGesture {
                            setAppIcon(icon.iconName)
                        }
                    }
                }
                .padding()
            }
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("App icon")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Funkce pro změnu ikony aplikace pomocí StoreKit (resp. API UIApplication)
    func setAppIcon(_ iconName: String?) {
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.selectedIconName = iconName
            }
        }
    }
}

struct AppIconSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppIconSelectionView()
        }
    }
}
