//
//  opensocialApp.swift
//  opensocial
//
//  Created by Filip Bukovina on 18.06.2024.
//

import SwiftUI
import Firebase

@main
struct SocialMediaApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
