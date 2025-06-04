//
//  MenuView.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct MenuView: View {
    @ObservedObject var viewModel: MenuViewModel
    @StateObject private var selectionManager = SelectionManager()
    @ObservedObject var preferences: UserPreferences
    @State private var showingSelection = false
    @State private var showingProfile = false
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss
    
    // Initializer to accept MenuViewModel
    init(viewModel: MenuViewModel, preferences: UserPreferences) {
        self.viewModel = viewModel
        self.preferences = preferences
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Header 
                    VStack(spacing: 16) {
                        FilterHeader(
                            selectedCategory: $viewModel.selectedCategory,
                            selectedDietTag: Binding(
                                get: { viewModel.selectedDietaryPreference },
                                set: { viewModel.updateDietaryPreference($0) }
                            ),
                            selectedNutritionSortPriority: Binding(
                                get: { viewModel.selectedNutritionSortPriority },
                                set: { viewModel.updateNutritionSortPriority($0) }
                            ),
                            searchText: $viewModel.searchText,
                            isSearching: $isSearching,
                            categories: viewModel.categories,
                            searchSuggestions: viewModel.getSearchSuggestions(),
                            onSuggestionTap: { suggestion in
                                viewModel.searchItems(with: suggestion)
                            },
                            showHighProteinTag: preferences.showHighProteinTag,
                            showLowFatTag: preferences.showLowFatTag,
                            showLowCarbsTag: preferences.showLowCarbsTag
                        )
                    }
                    .background(Color.white)
                  
                    
                    // Content Section
                    // Loading State
                    if viewModel.isLoading {
                        LoadingView()
                    }
                    // Error State
                    else if let errorMessage = viewModel.errorMessage {
                        ErrorView(
                            message: errorMessage,
                            onRetry: {
                                viewModel.clearError()
                                // Navigate back to camera to rescan
                                dismiss()
                            }
                        )
                    }
                    // Empty State
                    else if viewModel.filteredItems.isEmpty {
                        EmptyStateView(
                            hasActiveFilters: viewModel.hasActiveFilters,
                            onClearFilters: {
                                viewModel.clearAllFilters()
                                isSearching = false
                            }
                        )
                    }
                    // Menu List
                    else {
                        MenuListView(
                            filteredItems: viewModel.filteredItems,
                            selectionManager: selectionManager,
                            searchText: viewModel.searchText,
                            showHighProteinTag: preferences.showHighProteinTag,
                            showLowFatTag: preferences.showLowFatTag,
                            showLowCarbsTag: preferences.showLowCarbsTag,
                            onRefresh: {
                                Task {
                                    await viewModel.refreshMenu()
                                }
                            }
                        )
                    }
                }
                
                // Floating Cart Button
                if selectionManager.totalItems > 0 {
                    FloatingCartButton(
                        itemCount: selectionManager.totalItems,
                        action: { showingSelection = true }
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Menu")
                        .font(.system(.title2, design: .serif))
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Lens")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingSelection) {
                SelectionView(selectionManager: selectionManager)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(preferences: preferences)
            }
        }
        .onAppear {
            // Initialize filters with default values (only on first load)
            viewModel.initializeWithDefaults(from: preferences)
        }
        .onChange(of: preferences.defaultDietaryPreference) { newValue in
            // Don't automatically update the filter when default changes
            // User needs to restart the app or manually reset filters
        }
        .onChange(of: isSearching) { newValue in
            if !newValue {
                // When closing search, clear search text if empty
                if viewModel.searchText.isEmpty {
                    viewModel.clearSearch()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Processing menu...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6))
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6))
    }
}

struct EmptyStateView: View {
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasActiveFilters ? "magnifyingglass" : "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(hasActiveFilters ? "No items found" : "No menu items")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(hasActiveFilters ?
                 "Try adjusting your search or filters" :
                 "Menu items will appear here")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if hasActiveFilters {
                Button("Clear Filters") {
                    onClearFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6))
    }
}

struct MenuListView: View {
    let filteredItems: [String: [MenuItem]]
    let selectionManager: SelectionManager
    let searchText: String
    let showHighProteinTag: Bool
    let showLowFatTag: Bool
    let showLowCarbsTag: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(filteredItems.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.description.capitalized)
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredItems[category] ?? []) { item in
                                MenuItemRow(
                                    item: item,
                                    showHighProtein: showHighProteinTag,
                                    showLowFat: showLowFatTag,
                                    showLowCarbs: showLowCarbsTag,
                                    searchText: searchText,
                                    selectionManager: selectionManager
                                )
                                
                                if item.id != filteredItems[category]?.last?.id {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 80)
        }
    }
}

#Preview {
    MenuView(viewModel: MenuViewModel(), preferences: UserPreferences())
}
