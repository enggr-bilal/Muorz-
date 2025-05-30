//
//  SelectionManager.swift
//  Muorz
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

// MARK: - Supporting Models

/// Represents a selected menu item with its quantity
struct SelectedItem: Identifiable {
    /// Unique identifier matching the menu item's ID
    let id: UUID
    
    /// The selected menu item
    let menuItem: MenuItem
    
    /// Quantity of this item selected
    var quantity: Int
    
    /// Initializes a selected item
    /// - Parameters:
    ///   - menuItem: The menu item being selected
    ///   - quantity: Initial quantity (must be positive)
    init(menuItem: MenuItem, quantity: Int) {
        self.id = menuItem.id
        self.menuItem = menuItem
        self.quantity = max(1, quantity) // Ensure minimum quantity of 1
    }
    
    /// Computed total price for this selected item
    var totalPrice: Double {
        guard let priceString = menuItem.price else { return 0.0 }
        
        let cleanPrice = priceString
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "CHF", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        
        guard let price = Double(cleanPrice) else { return 0.0 }
        return price * Double(quantity)
    }
}

// MARK: - Selection Manager

/// ViewModel responsible for managing user's menu item selections
/// Handles adding, removing, and tracking quantities of selected items
@MainActor
class SelectionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of currently selected items with their quantities
    @Published private(set) var selectedItems: [SelectedItem] = []
    
    // MARK: - Configuration
    
    /// Maximum quantity allowed per individual item
    private let maxQuantityPerItem = 99
    
    /// Minimum quantity for any selected item
    private let minQuantityPerItem = 1
    
    // MARK: - Private Properties
    
    /// Cache for O(1) quantity lookups by item ID
    private var quantityCache: [UUID: Int] = [:]
    
    // MARK: - Public Methods
    
    /// Adds one unit of the specified menu item to the selection
    /// - Parameter item: Menu item to add
    func addItem(_ item: MenuItem) {
        let currentQuantity = quantityCache[item.id] ?? 0
        
        // Check if we can add more of this item
        guard currentQuantity < maxQuantityPerItem else {
            print("⚠️ Cannot add more of \(item.translatedName) - maximum quantity reached")
            return
        }
        
        let newQuantity = currentQuantity + 1
        
        if currentQuantity == 0 {
            // Add new item to selection
            let newItem = SelectedItem(menuItem: item, quantity: newQuantity)
            selectedItems.append(newItem)
            quantityCache[item.id] = newQuantity
            print("➕ Added new item: \(item.translatedName) (qty: \(newQuantity))")
        } else {
            // Update existing item quantity
            updateItemQuantity(item.id, to: newQuantity)
            print("➕ Increased \(item.translatedName) quantity to \(newQuantity)")
        }
    }
    
    /// Removes one unit of the specified menu item from the selection
    /// - Parameter item: Menu item to remove
    func removeItem(_ item: MenuItem) {
        guard let currentQuantity = quantityCache[item.id], currentQuantity > 0 else {
            print("⚠️ Cannot remove \(item.translatedName) - not in selection")
            return
        }
        
        let newQuantity = currentQuantity - 1
        
        if newQuantity == 0 {
            // Remove item completely from selection
            removeAllQuantities(item)
            print("➖ Removed \(item.translatedName) completely from selection")
        } else {
            // Update quantity
            updateItemQuantity(item.id, to: newQuantity)
            print("➖ Decreased \(item.translatedName) quantity to \(newQuantity)")
        }
    }
    
    /// Removes all quantities of the specified menu item from the selection
    /// - Parameter item: Menu item to remove completely
    func removeAllQuantities(_ item: MenuItem) {
        quantityCache.removeValue(forKey: item.id)
        selectedItems.removeAll { $0.menuItem.id == item.id }
        print("🗑️ Removed all quantities of \(item.translatedName)")
    }
    
    /// Sets a specific quantity for a menu item
    /// - Parameters:
    ///   - item: Menu item to update
    ///   - quantity: New quantity (0 removes the item, negative values are ignored)
    func setQuantity(for item: MenuItem, to quantity: Int) {
        guard quantity >= 0 else {
            print("⚠️ Invalid quantity \(quantity) for \(item.translatedName)")
            return
        }
        
        if quantity == 0 {
            removeAllQuantities(item)
        } else if quantity <= maxQuantityPerItem {
            let clampedQuantity = min(quantity, maxQuantityPerItem)
            
            if quantityCache[item.id] == nil {
                // Add new item
                let newItem = SelectedItem(menuItem: item, quantity: clampedQuantity)
                selectedItems.append(newItem)
                quantityCache[item.id] = clampedQuantity
            } else {
                // Update existing item
                updateItemQuantity(item.id, to: clampedQuantity)
            }
            print("📝 Set \(item.translatedName) quantity to \(clampedQuantity)")
        }
    }
    
    /// Returns the current quantity of the specified menu item
    /// - Parameter item: Menu item to check
    /// - Returns: Current quantity (0 if not selected)
    func quantity(for item: MenuItem) -> Int {
        return quantityCache[item.id] ?? 0
    }
    
    /// Checks if the specified menu item is currently selected
    /// - Parameter item: Menu item to check
    /// - Returns: True if the item is in the selection
    func isSelected(_ item: MenuItem) -> Bool {
        return quantityCache[item.id] != nil
    }
    
    /// Clears all selected items from the selection
    func clearSelection() {
        let itemCount = selectedItems.count
        selectedItems.removeAll()
        quantityCache.removeAll()
        print("🧹 Cleared selection of \(itemCount) items")
    }
    
    // MARK: - Computed Properties
    
    /// Total number of individual items in the selection (sum of all quantities)
    var totalItems: Int {
        return quantityCache.values.reduce(0, +)
    }
    
    /// Total estimated price of all selected items
    var totalPrice: Double {
        return selectedItems.reduce(0.0) { total, selectedItem in
            return total + selectedItem.totalPrice
        }
    }
    
    /// Number of unique menu items in the selection
    var uniqueItemCount: Int {
        return selectedItems.count
    }
    
    /// Returns true if the selection is empty
    var isEmpty: Bool {
        return selectedItems.isEmpty
    }
    
    /// Returns true if the selection has items
    var hasItems: Bool {
        return !selectedItems.isEmpty
    }
    
    // MARK: - Private Helper Methods
    
    /// Updates the quantity of an existing item in the selection
    /// - Parameters:
    ///   - itemId: ID of the item to update
    ///   - quantity: New quantity
    private func updateItemQuantity(_ itemId: UUID, to quantity: Int) {
        quantityCache[itemId] = quantity
        
        if let index = selectedItems.firstIndex(where: { $0.menuItem.id == itemId }) {
            var updatedItem = selectedItems[index]
            updatedItem.quantity = quantity
            selectedItems[index] = updatedItem
        }
    }
}

// MARK: - Selection Summary

extension SelectionManager {
    
    /// Returns a formatted summary of the current selection
    var selectionSummary: String {
        guard !isEmpty else { return "No items selected" }
        
        let itemsText = uniqueItemCount == 1 ? "item" : "items"
        let totalText = totalItems == 1 ? "piece" : "pieces"
        
        return "\(uniqueItemCount) \(itemsText) (\(totalItems) \(totalText)) - \(String(format: "%.2f", totalPrice))€"
    }
    
    /// Returns the most expensive item in the selection
    var mostExpensiveItem: SelectedItem? {
        return selectedItems.max { $0.totalPrice < $1.totalPrice }
    }
    
    /// Returns items grouped by category
    var itemsByCategory: [String: [SelectedItem]] {
        return Dictionary(grouping: selectedItems) { $0.menuItem.categoryEn }
    }
} 
