//
//  MenuView.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct MenuView: View {
    @StateObject private var viewModel = MenuViewModel()
    @StateObject private var selectionManager = SelectionManager()
    @ObservedObject var preferences: UserPreferences
    @State private var showingSelection = false
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(
                        searchText: $viewModel.searchText,
                        placeholder: "Search ingredients, dishes...",
                        suggestions: viewModel.getSearchSuggestions(),
                        onSuggestionTap: { suggestion in
                            viewModel.searchItems(with: suggestion)
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Search Results Summary
                    SearchResultsSummary(
                        resultsCount: viewModel.filteredItemsCount,
                        searchText: viewModel.searchText,
                        hasActiveFilters: viewModel.hasActiveFilters,
                        onClearFilters: {
                            viewModel.clearAllFilters()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, viewModel.hasActiveFilters ? 8 : 0)
                    
                    // Filter Header
                    FilterHeader(
                        selectedCategory: $viewModel.selectedCategory,
                        selectedDietTag: Binding(
                            get: { viewModel.selectedDietaryPreference },
                            set: { viewModel.updateDietaryPreference($0) }
                        ),
                        selectedNutritionTags: Binding(
                            get: { viewModel.selectedNutritionPreferences },
                            set: { viewModel.selectedNutritionPreferences = $0 }
                        ),
                        categories: viewModel.categories
                    )
                    
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
                                viewModel.loadSampleData()
                            }
                        )
                    }
                    // Empty State
                    else if viewModel.filteredItems.isEmpty {
                        EmptyStateView(
                            hasActiveFilters: viewModel.hasActiveFilters,
                            onClearFilters: {
                                viewModel.clearAllFilters()
                            }
                        )
                    }
                    // Menu List
                    else {
                        MenuListView(
                            filteredItems: viewModel.filteredItems,
                            selectionManager: selectionManager
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
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Menu")
                        .font(.system(.title2, design: .serif))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSelection) {
                SelectionView(selectionManager: selectionManager)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(preferences: preferences)
            }
            .refreshable {
                await viewModel.refreshMenu()
            }
        }
        .onAppear {
            // Sync preferences with ViewModel
            viewModel.selectedDietaryPreference = preferences.defaultDietaryPreference
            viewModel.selectedNutritionPreferences = preferences.defaultNutritionPreferences
        }
        .onChange(of: preferences.defaultDietaryPreference) { newValue in
            viewModel.updateDietaryPreference(newValue)
        }
        .onChange(of: preferences.defaultNutritionPreferences) { newValue in
            viewModel.selectedNutritionPreferences = newValue
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredItems.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.description.capitalized)
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredItems[category] ?? []) { item in
                                MenuItemRow(
                                    item: item,
                                    showHighProtein: true,
                                    showLowFat: true,
                                    showLowCarbs: true,
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
            .padding(.bottom, 80) // Add padding at the bottom for the floating button
        }
    }
}

#Preview {
    MenuView(preferences: UserPreferences())
}
