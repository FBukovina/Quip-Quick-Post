//
//  RootView.swift
//  opensocial
//
//  Created by Filip Bukovina on 18.01.2025.
//


import SwiftUI

struct RootView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        if logStatus {
            // Show your main/home screen here once the user is logged in
            MainView() 
        } else {
            // Show the login screen if the user isn't logged in
            LoginView()
        }
    }
}

struct MainContentView: View {
    var body: some View {
        Text("Welcome to the Main Content!")
            .font(.largeTitle)
    }
}
