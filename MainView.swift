//
//  MainView.swift
//  opensocial
//
//  Created by Filip Bukovina on 21.06.2024.
//

import SwiftUI

enum TabSelection {
    case home, search, assist, profile
}

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: TabSelection = .home

    var body: some View {
        ZStack {
            // VisionOS-like pozadí
            LinearGradient(
                gradient: Gradient(colors: [Color("VisionBackgroundStart"), Color("VisionBackgroundEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Obsah podle vybrané záložky
            Group {
                switch selectedTab {
                case .home:
                    PostsView()
                case .search:
                    SearchView()
                case .assist:
                    AIChatView()
                case .profile:
                    ProfileView()
                }
            }
            
            // Vlastní plovoucí tab bar
            VStack {
                Spacer()
                
                HStack(spacing: 30) {
                    tabBarIcon(systemName: "rectangle.portrait.on.rectangle.portrait.angled", tab: .home)
                    tabBarIcon(systemName: "magnifyingglass", tab: .search)
                    tabBarIcon(systemName: "slash.circle", tab: .assist)
                    tabBarIcon(systemName: "person", tab: .profile)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(colorScheme)
    }
    
    // Ikonka pro tab bar
    @ViewBuilder
    private func tabBarIcon(systemName: String, tab: TabSelection) -> some View {
        Button {
            withAnimation(.easeInOut) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                .padding(8)
        }
    }
}

struct UserDefaultsEditorView: View {
    @State private var userDefaultsDict: [String: Any] = [:]
    @State private var refreshTrigger = false
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some View {
        List {
            Toggle("Subscr.stat.", isOn: $subscriptionManager.isPurchased)
            ForEach(userDefaultsDict.keys.sorted(), id: \.self) { key in
                if let value = userDefaultsDict[key] {
                    HStack {
                        Text(key).bold()
                        Spacer()
                        getEditor(for: key, value: value)
                    }
                }
            }
        }
        .onAppear(perform: loadUserDefaults)
    }
    
    private func getEditor(for key: String, value: Any) -> some View {
        if let boolValue = value as? Bool {
            return AnyView(
                Toggle("", isOn: Binding(
                    get: { boolValue },
                    set: { newValue in
                        UserDefaults.standard.set(newValue, forKey: key)
                        loadUserDefaults()
                    }
                ))
            )
        } else if let stringValue = value as? String {
            return AnyView(
                TextField("Value", text: Binding(
                    get: { stringValue },
                    set: { newValue in
                        UserDefaults.standard.set(newValue, forKey: key)
                        loadUserDefaults()
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 150)
            )
        } else if let intValue = value as? Int {
            return AnyView(
                Stepper(value: Binding(
                    get: { intValue },
                    set: { newValue in
                        UserDefaults.standard.set(newValue, forKey: key)
                        loadUserDefaults()
                    }
                ), label: { Text("\(intValue)") })
            )
        } else if let doubleValue = value as? Double {
            return AnyView(
                TextField("", text: Binding(
                    get: { String(doubleValue) },
                    set: { newValue in
                        if let doubleVal = Double(newValue) {
                            UserDefaults.standard.set(doubleVal, forKey: key)
                            loadUserDefaults()
                        }
                    }
                ))
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
            )
        } else {
            return AnyView(Text("Unsupported Type").foregroundColor(.gray))
        }
    }
    
    private func loadUserDefaults() {
        let defaults = UserDefaults.standard.dictionaryRepresentation()
        userDefaultsDict = defaults
        refreshTrigger.toggle()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        MainView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
    }
}
