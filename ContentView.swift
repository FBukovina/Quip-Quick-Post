//
//  ContentView.swift
//  opensocial
//
//  Created by Filip Bukovina on 18.06.2024.
//

import SwiftUI
import Firebase
import FirebaseCore

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        // MARK: Redirecting User Based on Log Status
        if logStatus{
            Text("Main View")
        }else{
            MainView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
