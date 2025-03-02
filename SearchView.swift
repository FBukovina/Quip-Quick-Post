//
//  SearchView.swift
//  opensocial
//
//  Created by Filip Bukovina on 12.02.2025.
//


import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Modely

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let profileImageURL: String?
}

struct Trend: Identifiable, Codable {
    @DocumentID var id: String?
    let keyword: String
    let count: Int
}

// MARK: - ViewModel pro hledání

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var users: [AppUser] = []
    @Published var trends: [Trend] = []
    @Published var isLoading: Bool = false
    
    private var db = Firestore.firestore()
    
    init() {
        fetchTrends()
    }
    
    /// Vyhledá uživatele podle zadaného dotazu (case-insensitive)
    func searchUsers() async {
        let queryText = searchQuery.trimmingCharacters(in: CharacterSet.whitespaces)
        // Pokud je dotaz prázdný, vymažeme výsledky
        guard !queryText.isEmpty else {
            self.users = []
            return
        }
        
        isLoading = true
        do {
            let snapshot = try await db.collection("users")
                .whereField("name", isGreaterThanOrEqualTo: queryText)
                .whereField("name", isLessThanOrEqualTo: queryText + "\u{f8ff}")
                .getDocuments()
            
            let fetchedUsers = snapshot.documents.compactMap { document in
                try? document.data(as: AppUser.self)
            }
            self.users = fetchedUsers
        } catch {
            print("Chyba při vyhledávání uživatelů: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    /// Načte aktuální trendy z kolekce "trends" – seřazené sestupně podle počtu
    func fetchTrends() {
        db.collection("trends")
            .order(by: "count", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Chyba při načítání trendů: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    let fetchedTrends = snapshot.documents.compactMap { document in
                        try? document.data(as: Trend.self)
                    }
                    DispatchQueue.main.async {
                        self.trends = fetchedTrends
                    }
                }
            }
    }
}

// MARK: - SearchView

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Vyhledávací pole
                TextField("Search ...", text: $viewModel.searchQuery, onCommit: {
                    Task {
                        await viewModel.searchUsers()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .padding(.top)
                
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                }
                
                List {
                    // Sekce pro výsledky hledání (zobrazí se, pokud je dotaz ne-prázdný)
                    if !viewModel.searchQuery.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
                        Section(header: Text("Search results")) {
                            if viewModel.users.isEmpty {
                                Text("No users found.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.users) { user in
                                    HStack {
                                        // Načítá se profilový obrázek, pokud je k dispozici
                                        if let urlString = user.profileImageURL,
                                           let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 40, height: 40)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 40, height: 40)
                                                        .clipShape(Circle())
                                                case .failure:
                                                    Image(systemName: "person.crop.circle.badge.exclam")
                                                        .frame(width: 40, height: 40)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        } else {
                                            Image(systemName: "person.crop.circle")
                                                .resizable()
                                                .frame(width: 40, height: 40)
                                        }
                                        Text(user.name)
                                            .font(.body)
                                            .padding(.leading, 8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sekce pro trendy
                    Section(header: Text("Trending now")) {
                        if viewModel.trends.isEmpty {
                            Text("Not trending yet.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.trends) { trend in
                                HStack {
                                    Text(trend.keyword)
                                        .font(.body)
                                    Spacer()
                                    Text("\(trend.count)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Search")
            .onChange(of: viewModel.searchQuery) { newValue in
                if newValue.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
                    viewModel.users = []
                }
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
