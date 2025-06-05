//
//  MenuViewModel.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation
import Combine

@MainActor
class MenuViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var menuItems: [MenuItem] = []
    @Published var restaurantInfo: RestaurantInfo?
    @Published var currency: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory = "all"
    @Published var selectedDietaryPreference: String?
    @Published var selectedNutritionSortPriority: String?
    
    // MARK: - Temporary Filter Properties (reset on each app launch)
    
    // MARK: - Constants
    
    private let highProteinThreshold = 6
    private let lowFatThreshold = 5
    private let lowCarbsThreshold = 4
    
    // MARK: - Dependencies
    
    private let menuService: MenuServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var categories: [String] {
        ["all"] + Array(Set(menuItems.map { $0.categoryEn })).sorted()
    }
    
    var filteredItems: [String: [MenuItem]] {
        let filtered = menuItems
            .filter { item in
                // Search filter
                item.matchesSearchQuery(searchText)
            }
            .filter { item in
                // Category filter
                selectedCategory == "all" || item.categoryEn == selectedCategory
            }
            .filter { item in
                // Dietary preference filter
                item.matchesDietaryPreference(selectedDietaryPreference)
            }
        
        // Group by category and sort within each category
        let grouped = Dictionary(grouping: filtered) { $0.categoryEn }
        
        // Apply sorting within each category based on nutrition priority
        var sortedGrouped: [String: [MenuItem]] = [:]
        for (category, items) in grouped {
            sortedGrouped[category] = sortItemsByNutritionPriority(items, priority: selectedNutritionSortPriority ?? "none")
        }
        
        return sortedGrouped
    }
    
    var hasActiveFilters: Bool {
        return !searchText.isEmpty ||
               selectedCategory != "all" ||
               selectedDietaryPreference != nil
    }
    
    var filteredItemsCount: Int {
        return filteredItems.values.flatMap { $0 }.count
    }
    
    /// Check if menu has pricing information
    var hasPricing: Bool {
        return currency != nil && menuItems.contains { $0.hasPrice }
    }
    
    // MARK: - Initialization
    
    init(menuService: MenuServiceProtocol = MenuService()) {
        self.menuService = menuService
        setupSearchDebouncing()
    }
    
    // MARK: - Public Methods
    
    func processOCRText(_ text: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await menuService.processOCRText(text)
            menuItems = response.menuItems
            restaurantInfo = response.restaurantInfo
            currency = response.currency
        } catch {
            errorMessage = error.localizedDescription
            print("Error processing OCR text: \(error)")
        }
        
        isLoading = false
    }
    
    func clearAllFilters() {
        searchText = ""
        selectedCategory = "all"
        selectedDietaryPreference = nil
        // Note: We don't reset selectedNutritionSortPriority here as it's more of a preference than a filter
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func clearMenuData() {
        menuItems = []
        restaurantInfo = nil
        errorMessage = nil
    }
    
    func refreshMenu() async {
        // Clear menu data to force new scan
        clearMenuData()
        clearError()
    }
    
    // MARK: - Filter Methods (temporary filters, don't affect defaults)
    
    func updateDietaryPreference(_ preference: String?) {
        selectedDietaryPreference = preference
    }
    
    func updateNutritionSortPriority(_ priority: String) {
        selectedNutritionSortPriority = priority
    }
    
    // MARK: - Sorting Methods
    
    private func sortItemsByNutritionPriority(_ items: [MenuItem], priority: String) -> [MenuItem] {
        switch priority {
        case "protein":
            return items.sorted { $0.nutritionScores.protein > $1.nutritionScores.protein }
        case "fat":
            return items.sorted { $0.nutritionScores.fat < $1.nutritionScores.fat }
        case "carbs":
            return items.sorted { $0.nutritionScores.carbs < $1.nutritionScores.carbs }
        default:
            return items // No sorting for "none"
        }
    }
    
    // MARK: - Initialization from User Preferences
    
    func initializeWithDefaults(from preferences: UserPreferences) {
        // Initialize temporary filters with default values
        selectedDietaryPreference = preferences.defaultDietaryPreference
        selectedNutritionSortPriority = preferences.defaultNutritionSortPriority
    }
    
    // MARK: - Search Methods
    
    func searchItems(with query: String) {
        searchText = query
    }
    
    func getSearchSuggestions() -> [String] {
        let allIngredients = menuItems.flatMap { $0.ingredientsEn }
        let uniqueIngredients = Array(Set(allIngredients)).sorted()
        
        if searchText.isEmpty {
            return Array(uniqueIngredients.prefix(5))
        }
        
        return uniqueIngredients.filter { ingredient in
            ingredient.lowercased().contains(searchText.lowercased())
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebouncing() {
        // Debounce search to avoid excessive filtering
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Search is automatically applied through computed property
                // This is just for potential analytics or logging
                self?.logSearchQuery()
            }
            .store(in: &cancellables)
    }
    
    private func logSearchQuery() {
        if !searchText.isEmpty {
            print("Search query: \(searchText), Results: \(filteredItemsCount)")
        }
    }
}

// MARK: - Error Handling

extension MenuViewModel {
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}
