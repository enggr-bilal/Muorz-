//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import Foundation

struct SelectedItem: Identifiable {
    let id: UUID
    let menuItem: MenuItem
    var quantity: Int
    
    init(menuItem: MenuItem, quantity: Int) {
        self.id = menuItem.id
        self.menuItem = menuItem
        self.quantity = quantity
    }
}

@MainActor
class SelectionManager: ObservableObject {
    @Published private(set) var selectedItems: [SelectedItem] = []
    private let maxQuantityPerItem = 99
    
    // Dictionary for O(1) lookup of quantities
    private var quantityCache: [UUID: Int] = [:]
    
    // MARK: - Public Methods
    
    func addItem(_ item: MenuItem) {
        guard let currentQuantity = quantityCache[item.id], currentQuantity < maxQuantityPerItem else {
            // If item doesn't exist or is at max quantity, add it with quantity 1
            if quantityCache[item.id] == nil {
                let newItem = SelectedItem(menuItem: item, quantity: 1)
                selectedItems.append(newItem)
                quantityCache[item.id] = 1
            }
            return
        }
        
        // Update both cache and array
        let newQuantity = currentQuantity + 1
        quantityCache[item.id] = newQuantity
        
        if let index = selectedItems.firstIndex(where: { $0.menuItem.id == item.id }) {
            var updatedItem = selectedItems[index]
            updatedItem.quantity = newQuantity
            selectedItems[index] = updatedItem
        }
    }
    
    func removeItem(_ item: MenuItem) {
        guard let currentQuantity = quantityCache[item.id], currentQuantity > 0 else {
            return
        }
        
        let newQuantity = currentQuantity - 1
        
        if newQuantity == 0 {
            // Remove item completely
            quantityCache.removeValue(forKey: item.id)
            selectedItems.removeAll { $0.menuItem.id == item.id }
        } else {
            // Update both cache and array
            quantityCache[item.id] = newQuantity
            if let index = selectedItems.firstIndex(where: { $0.menuItem.id == item.id }) {
                var updatedItem = selectedItems[index]
                updatedItem.quantity = newQuantity
                selectedItems[index] = updatedItem
            }
        }
    }
    
    func removeAllQuantities(_ item: MenuItem) {
        quantityCache.removeValue(forKey: item.id)
        selectedItems.removeAll { $0.menuItem.id == item.id }
    }
    
    func quantity(for item: MenuItem) -> Int {
        quantityCache[item.id] ?? 0
    }
    
    func isSelected(_ item: MenuItem) -> Bool {
        quantityCache[item.id] != nil
    }
    
    var totalItems: Int {
        quantityCache.values.reduce(0, +)
    }
    
    var totalPrice: Double {
        selectedItems.reduce(0.0) { total, selectedItem in
            let itemPrice = selectedItem.menuItem.price?
                .replacingOccurrences(of: "€", with: "")
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: ",", with: ".")
            
            if let price = itemPrice.flatMap(Double.init) {
                return total + (price * Double(selectedItem.quantity))
            }
            return total
        }
    }
    
    func clearSelection() {
        selectedItems.removeAll()
        quantityCache.removeAll()
    }
} 
