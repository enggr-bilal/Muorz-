//
//  SearchBar.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    @State private var isEditing = false
    @State private var showSuggestions = false
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search ingredients...",
        suggestions: [String] = [],
        onSuggestionTap: @escaping (String) -> Void = { _ in }
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.suggestions = suggestions
        self.onSuggestionTap = onSuggestionTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing = true
                            showSuggestions = !suggestions.isEmpty
                        }
                    }
                    .onChange(of: searchText) { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSuggestions = isEditing && !suggestions.isEmpty
                        }
                    }
                
                if isEditing {
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                            isEditing = false
                            showSuggestions = false
                            hideKeyboard()
                        }
                    }
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16))
                }
                
                if !searchText.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Suggestions
            if showSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions.prefix(5), id: \.self) { suggestion in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                searchText = suggestion
                                showSuggestions = false
                                isEditing = false
                                onSuggestionTap(suggestion)
                                hideKeyboard()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                                
                                Text(suggestion)
                                    .foregroundColor(.primary)
                                    .font(.system(size: 16))
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if suggestion != suggestions.prefix(5).last {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onTapGesture {
            // Dismiss suggestions when tapping outside
            if showSuggestions {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSuggestions = false
                    isEditing = false
                    hideKeyboard()
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Search Results Summary

struct SearchResultsSummary: View {
    let resultsCount: Int
    let searchText: String
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    
    var body: some View {
        if hasActiveFilters {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if !searchText.isEmpty {
                        Text("Search results for \"\(searchText)\"")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Text("\(resultsCount) item\(resultsCount == 1 ? "" : "s") found")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Clear") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onClearFilters()
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SearchBar(
            searchText: .constant(""),
            suggestions: ["tomato", "cheese", "pasta", "chicken", "vegetables"]
        )
        
        SearchBar(
            searchText: .constant("tom"),
            suggestions: ["tomato", "tomato sauce", "cherry tomatoes"]
        )
        
        SearchResultsSummary(
            resultsCount: 5,
            searchText: "tomato",
            hasActiveFilters: true,
            onClearFilters: {}
        )
    }
    .padding()
} 