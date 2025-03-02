//
//  ChangelogView.swift
//  opensocial
//
//  Created by Filip Bukovina on 01.03.2025.
//

import SwiftUI

// The main SwiftUI view to display the changelog
struct ChangelogView: View {
    @State private var versions: [Version] = []
    
    var body: some View {
        List(versions) { version in
            Section(header: Text("Version \(version.versionNumber) (\(version.releaseDate))").font(.headline)) {
                ForEach(version.changes.keys.sorted(), id: \.self) { category in
                    Section(header: Text(category).font(.subheadline)) {
                        ForEach(version.changes[category]!, id: \.self) { change in
                            Text("- \(change)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Changelog")
        .onAppear {
            loadChangelog()
        }
    }
    
    // Load the changelog from the bundle
    func loadChangelog() {
        guard let filePath = Bundle.main.path(forResource: "CHANGELOG", ofType: "md") else {
            print("Changelog file not found in bundle")
            versions = []
            return
        }
        versions = parseChangelog(filePath: filePath)
    }
}

// Struct to represent a version in the changelog, conforming to Identifiable for SwiftUI
struct Version: Identifiable {
    let id = UUID()
    let versionNumber: String
    let releaseDate: String
    var changes: [String: [String]] // Maps categories (e.g., "Added") to lists of changes
}

// Function to parse the changelog file into an array of Version structs
func parseChangelog(filePath: String) -> [Version] {
    do {
        let content = try String(contentsOfFile: filePath)
        let lines = content.components(separatedBy: .newlines)
        
        var versions: [Version] = []
        var currentCategory: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Parse version heading: ## [version] - date
            if trimmed.hasPrefix("## [") {
                let versionPattern = "^##\\s*\\[(.+?)\\]\\s*-\\s*(.+)$"
                if let match = trimmed.matching(regex: versionPattern), match.count >= 3 {
                    let versionNumber = match[1]
                    let releaseDate = match[2]
                    versions.append(Version(versionNumber: versionNumber, releaseDate: releaseDate, changes: [:]))
                    currentCategory = nil // Reset category for new version
                } else {
                    print("Failed to parse version heading: \(trimmed)")
                }
            }
            // Parse category heading: ### Category
            else if trimmed.hasPrefix("### ") {
                let categoryPattern = "^###\\s*(.+)$"
                if let match = trimmed.matching(regex: categoryPattern), !versions.isEmpty {
                    currentCategory = match[1]
                }
            }
            // Parse change item: - Description
            else if trimmed.hasPrefix("- ") {
                let itemPattern = "^-\\s*(.+)$"
                if let match = trimmed.matching(regex: itemPattern),
                   let category = currentCategory,
                   !versions.isEmpty {
                    let item = match[1]
                    versions[versions.count - 1].changes[category, default: []].append(item)
                }
            }
        }
        
        return versions
    } catch {
        print("Error reading file: \(error)")
        return []
    }
}

// Extension to handle regex matching
extension String {
    func matching(regex: String) -> [String]? {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let range = NSRange(location: 0, length: self.utf16.count)
            if let match = regex.firstMatch(in: self, options: [], range: range) {
                var results: [String] = []
                for i in 0..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: self) {
                        results.append(String(self[range]))
                    }
                }
                return results
            }
        } catch {
            print("Invalid regex: \(error)")
        }
        return nil
    }
}

// Preview provider for SwiftUI previews
struct ChangelogView_Previews: PreviewProvider {
    static var previews: some View {
        ChangelogView()
    }
}
