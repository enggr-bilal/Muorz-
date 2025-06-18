//
//  ScannedMenuService.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class ScannedMenuService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var scannedMenus: [ScannedMenu] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Check if this service is using the correct model context
    func isUsingContext(_ context: ModelContext) -> Bool {
        return self.modelContext === context
    }
    
    /// Create a new service instance with the given context
    static func create(with context: ModelContext) -> ScannedMenuService {
        return ScannedMenuService(modelContext: context)
    }
    
    /// Save a new scanned menu to persistent storage
    func saveScannedMenu(_ menuResponse: MenuResponse) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let scannedMenu = ScannedMenu(from: menuResponse)
            modelContext.insert(scannedMenu)
            try modelContext.save()
            
            // Refresh the list
            await loadScannedMenus()
            
            print("✅ Menu scanné sauvegardé: \(scannedMenu.displayName)")
        } catch {
            errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
            print("❌ Erreur sauvegarde menu: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    /// Load all scanned menus from persistent storage
    func loadScannedMenus() async {
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<ScannedMenu>(
                sortBy: [SortDescriptor(\.scannedAt, order: .reverse)]
            )
            scannedMenus = try modelContext.fetch(descriptor)
            
            print("📚 \(scannedMenus.count) menus chargés depuis la base de données")
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
            print("❌ Erreur chargement menus: \(error)")
        }
        
        isLoading = false
    }
    
    /// Delete a scanned menu
    func deleteScannedMenu(_ menu: ScannedMenu) async throws {
        isLoading = true
        
        do {
            modelContext.delete(menu)
            try modelContext.save()
            
            // Refresh the list
            await loadScannedMenus()
            
            print("🗑️ Menu supprimé: \(menu.displayName)")
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
            print("❌ Erreur suppression menu: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    /// Update a scanned menu (favorites, notes, tags)
    func updateScannedMenu(_ menu: ScannedMenu) async throws {
        isLoading = true
        
        do {
            try modelContext.save()
            print("✅ Menu mis à jour: \(menu.displayName)")
        } catch {
            errorMessage = "Erreur lors de la mise à jour: \(error.localizedDescription)"
            print("❌ Erreur mise à jour menu: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    /// Search scanned menus
    func searchScannedMenus(query: String) async -> [ScannedMenu] {
        guard !query.isEmpty else {
            return scannedMenus
        }
        
        return scannedMenus.filter { $0.matchesSearchQuery(query) }
    }
    
    /// Filter scanned menus by dietary preference
    func filterScannedMenus(by dietaryPreference: String?) async -> [ScannedMenu] {
        guard let preference = dietaryPreference else {
            return scannedMenus
        }
        
        return scannedMenus.filter { $0.matchesDietaryPreference(preference) }
    }
    
    /// Filter scanned menus by category
    func filterScannedMenus(by category: String) async -> [ScannedMenu] {
        guard category != "all" else {
            return scannedMenus
        }
        
        return scannedMenus.filter { $0.matchesCategory(category) }
    }
    
    /// Get favorite menus
    func getFavoriteMenus() async -> [ScannedMenu] {
        return scannedMenus.filter { $0.isFavorite }
    }
    
    /// Get menus by date range
    func getMenus(from startDate: Date, to endDate: Date) async -> [ScannedMenu] {
        return scannedMenus.filter { menu in
            menu.scannedAt >= startDate && menu.scannedAt <= endDate
        }
    }
    
    /// Get recent menus (last 7 days)
    func getRecentMenus() async -> [ScannedMenu] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return await getMenus(from: oneWeekAgo, to: Date())
    }
    
    /// Get statistics
    func getStatistics() -> ScannedMenuStatistics {
        let totalMenus = scannedMenus.count
        let favoriteMenus = scannedMenus.filter { $0.isFavorite }.count
        let totalItems = scannedMenus.reduce(0) { $0 + $1.totalItems }
        let totalPrice = scannedMenus.reduce(0.0) { $0 + $1.totalPrice }
        
        // Get unique restaurants
        let uniqueRestaurants = Set(scannedMenus.compactMap { $0.restaurantName })
        
        // Get most common cuisines
        let cuisineCounts = Dictionary(grouping: scannedMenus.compactMap { $0.restaurantCuisine }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return ScannedMenuStatistics(
            totalMenus: totalMenus,
            favoriteMenus: favoriteMenus,
            totalItems: totalItems,
            totalPrice: totalPrice,
            uniqueRestaurants: uniqueRestaurants.count,
            mostCommonCuisines: Array(cuisineCounts.prefix(5))
        )
    }
    
    /// Clear all scanned menus (for testing or user request)
    func clearAllMenus() async throws {
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<ScannedMenu>()
            let allMenus = try modelContext.fetch(descriptor)
            
            for menu in allMenus {
                modelContext.delete(menu)
            }
            
            try modelContext.save()
            scannedMenus = []
            
            print("🗑️ Tous les menus supprimés")
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
            print("❌ Erreur suppression tous les menus: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    /// Permet de mettre à jour le contexte si besoin
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe changes in the model context
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                Task {
                    await self?.loadScannedMenus()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Statistics Model

struct ScannedMenuStatistics {
    let totalMenus: Int
    let favoriteMenus: Int
    let totalItems: Int
    let totalPrice: Double
    let uniqueRestaurants: Int
    let mostCommonCuisines: [(String, Int)]
    
    var averageItemsPerMenu: Double {
        guard totalMenus > 0 else { return 0 }
        return Double(totalItems) / Double(totalMenus)
    }
    
    var averagePricePerMenu: Double {
        guard totalMenus > 0 else { return 0 }
        return totalPrice / Double(totalMenus)
    }
    
    var favoritePercentage: Double {
        guard totalMenus > 0 else { return 0 }
        return (Double(favoriteMenus) / Double(totalMenus)) * 100
    }
}

// MARK: - Error Handling

extension ScannedMenuService {
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
} 