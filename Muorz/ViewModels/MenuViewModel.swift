//
//  MenuViewModel.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation
import Combine

/// ViewModel responsible for managing menu data and filtering operations
/// Handles menu display, search, filtering, and sorting functionality
@MainActor
class MenuViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of menu items from the processed menu
    @Published var menuItems: [MenuItem] = []
    
    /// Indicates if menu processing is in progress
    @Published var isLoading = false
    
    /// Error message from the last failed operation
    @Published var errorMessage: String?
    
    /// Current search query text
    @Published var searchText = ""
    
    /// Currently selected category filter
    @Published var selectedCategory = "all"
    
    /// Restaurant information from the processed menu
    @Published var restaurantInfo: RestaurantInfo?
    
    // MARK: - Session Filter Properties
    // These filters are reset on each app launch and don't persist
    
    /// Currently selected dietary preference filter
    @Published var selectedDietaryPreference: String?
    
    /// Current nutrition-based sorting priority
    @Published var selectedNutritionSortPriority: String = "none"
    
    // MARK: - Configuration Constants
    
    /// Threshold for considering an item high in protein
    private let highProteinThreshold = 6
    
    /// Threshold for considering an item low in fat
    private let lowFatThreshold = 5
    
    /// Threshold for considering an item low in carbs
    private let lowCarbsThreshold = 4
    
    // MARK: - Dependencies
    
    /// Service responsible for processing OCR text into menu data
    private let menuService: MenuServiceProtocol
    
    /// Set of Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Returns all available categories including "all" option
    var categories: [String] {
        ["all"] + Array(Set(menuItems.map { $0.categoryEn })).sorted()
    }
    
    /// Returns filtered and grouped menu items based on current filters
    var filteredItems: [String: [MenuItem]] {
        let filtered = applyFilters(to: menuItems)
        let grouped = Dictionary(grouping: filtered) { $0.categoryEn }
        
        // Apply sorting within each category based on nutrition priority
        var sortedGrouped: [String: [MenuItem]] = [:]
        for (category, items) in grouped {
            sortedGrouped[category] = applySorting(to: items, priority: selectedNutritionSortPriority)
        }
        
        return sortedGrouped
    }
    
    /// Returns true if any filters are currently active
    var hasActiveFilters: Bool {
        return !searchText.isEmpty ||
               selectedCategory != "all" ||
               selectedDietaryPreference != nil
    }
    
    /// Returns the total count of filtered items
    var filteredItemsCount: Int {
        return filteredItems.values.flatMap { $0 }.count
    }
    
    // MARK: - Initialization
    
    /// Initializes the menu view model with optional dependency injection
    /// - Parameter menuService: Service for processing menu data (uses default if nil)
    init(menuService: MenuServiceProtocol = MenuService()) {
        self.menuService = menuService
        setupSearchDebouncing()
    }
    
    // MARK: - Menu Processing Methods
    
    /// Processes OCR text through the menu service
    /// - Parameter text: Raw OCR text to process
    func processOCRText(_ text: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await menuService.processOCRText(text)
            menuItems = response.menuItems
            restaurantInfo = response.restaurantInfo
            print("✅ Menu processed: \(menuItems.count) items from \(categories.count - 1) categories")
        } catch {
            handleError(error)
            print("❌ Menu processing failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Clears all menu data and resets the view model
    func clearMenuData() {
        menuItems = []
        restaurantInfo = nil
        errorMessage = nil
        print("🧹 Menu data cleared")
    }
    
    /// Refreshes the menu by clearing current data
    func refreshMenu() async {
        clearMenuData()
        clearError()
    }
    
    // MARK: - Filter Management Methods
    
    /// Clears all active filters except nutrition sort priority
    func clearAllFilters() {
        searchText = ""
        selectedCategory = "all"
        selectedDietaryPreference = nil
        print("🔄 All filters cleared")
    }
    
    /// Clears only the search text
    func clearSearch() {
        searchText = ""
    }
    
    /// Updates the dietary preference filter
    /// - Parameter preference: New dietary preference (nil to clear)
    func updateDietaryPreference(_ preference: String?) {
        selectedDietaryPreference = preference
        print("🥗 Dietary preference updated: \(preference ?? "none")")
    }
    
    /// Updates the nutrition sorting priority
    /// - Parameter priority: New sorting priority ("protein", "fat", "carbs", or "none")
    func updateNutritionSortPriority(_ priority: String) {
        selectedNutritionSortPriority = priority
        print("📊 Nutrition sort priority updated: \(priority)")
    }
    
    /// Initializes filters with default values from user preferences
    /// - Parameter preferences: User preferences containing default filter values
    func initializeWithDefaults(from preferences: UserPreferences) {
        selectedDietaryPreference = preferences.defaultDietaryPreference
        selectedNutritionSortPriority = preferences.defaultNutritionSortPriority
        print("⚙️ Filters initialized with user defaults")
    }
    
    // MARK: - Search Methods
    
    /// Updates the search query
    /// - Parameter query: New search query text
    func searchItems(with query: String) {
        searchText = query
    }
    
    /// Returns search suggestions based on current menu items
    /// - Returns: Array of suggested search terms
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
    
    // MARK: - Private Filter and Sort Methods
    
    /// Applies all active filters to the given menu items
    /// - Parameter items: Array of menu items to filter
    /// - Returns: Filtered array of menu items
    private func applyFilters(to items: [MenuItem]) -> [MenuItem] {
        return items
            .filter { item in
                // Apply search filter
                item.matchesSearchQuery(searchText)
            }
            .filter { item in
                // Apply category filter
                selectedCategory == "all" || item.categoryEn == selectedCategory
            }
            .filter { item in
                // Apply dietary preference filter
                item.matchesDietaryPreference(selectedDietaryPreference)
            }
    }
    
    /// Applies sorting to menu items based on nutrition priority
    /// - Parameters:
    ///   - items: Array of menu items to sort
    ///   - priority: Sorting priority ("protein", "fat", "carbs", or "none")
    /// - Returns: Sorted array of menu items
    private func applySorting(to items: [MenuItem], priority: String) -> [MenuItem] {
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
    
    /// Sets up search debouncing to avoid excessive filtering operations
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.logSearchQuery()
            }
            .store(in: &cancellables)
    }
    
    /// Logs search queries for debugging and analytics
    private func logSearchQuery() {
        if !searchText.isEmpty {
            print("🔍 Search query: '\(searchText)', Results: \(filteredItemsCount)")
        }
    }
}

// MARK: - Error Handling

extension MenuViewModel {
    
    /// Handles errors by setting error message and stopping loading state
    /// - Parameter error: Error to handle
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
        print("❌ MenuViewModel error: \(error.localizedDescription)")
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
}
