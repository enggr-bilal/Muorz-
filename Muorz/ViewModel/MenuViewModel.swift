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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory = "all"
    @Published var restaurantInfo: RestaurantInfo?
    
    // MARK: - Temporary Filter Properties (reset on each app launch)
    @Published var selectedDietaryPreference: String?
    @Published var selectedNutritionPreferences: Set<String> = []
    
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
            .filter { item in
                // Nutrition preference filter
                item.matchesNutritionPreferences(
                    selectedNutritionPreferences,
                    highProteinThreshold: highProteinThreshold,
                    lowFatThreshold: lowFatThreshold,
                    lowCarbsThreshold: lowCarbsThreshold
                )
            }
        
        return Dictionary(grouping: filtered) { $0.categoryEn }
    }
    
    var hasActiveFilters: Bool {
        return !searchText.isEmpty ||
               selectedCategory != "all" ||
               selectedDietaryPreference != nil ||
               !selectedNutritionPreferences.isEmpty
    }
    
    var filteredItemsCount: Int {
        return filteredItems.values.flatMap { $0 }.count
    }
    
    // MARK: - Initialization
    
    init(menuService: MenuServiceProtocol = MenuService()) {
        self.menuService = menuService
        loadSampleData()
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
        } catch {
            errorMessage = error.localizedDescription
            print("Error processing OCR text: \(error)")
        }
        
        isLoading = false
    }
    
    func loadSampleData() {
        menuItems = menuService.loadSampleMenu()
    }
    
    func clearAllFilters() {
        searchText = ""
        selectedCategory = "all"
        selectedDietaryPreference = nil
        selectedNutritionPreferences.removeAll()
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func refreshMenu() async {
        // For future implementation when we have real data source
        loadSampleData()
    }
    
    // MARK: - Filter Methods (temporary filters, don't affect defaults)
    
    func updateDietaryPreference(_ preference: String?) {
        selectedDietaryPreference = preference
    }
    
    func toggleNutritionPreference(_ preference: String) {
        if selectedNutritionPreferences.contains(preference) {
            selectedNutritionPreferences.remove(preference)
        } else {
            selectedNutritionPreferences.insert(preference)
        }
    }
    
    func clearNutritionPreferences() {
        selectedNutritionPreferences.removeAll()
    }
    
    // MARK: - Initialization from User Preferences
    
    func initializeWithDefaults(from preferences: UserPreferences) {
        // Initialize temporary filters with default values
        selectedDietaryPreference = preferences.defaultDietaryPreference
        selectedNutritionPreferences.removeAll() // Nutrition filters start empty
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
