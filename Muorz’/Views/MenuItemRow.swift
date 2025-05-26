//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct MenuItemRow: View {
    let item: MenuItem
    let showHighProtein: Bool
    let showLowFat: Bool
    let showLowCarbs: Bool
    @ObservedObject var selectionManager: SelectionManager
    
    // Thresholds for nutritional tags
    private let highProteinThreshold = 6
    private let lowFatThreshold = 5
    private let lowCarbsThreshold = 4
    
    private var isHighProtein: Bool {
        item.nutritionScores.protein >= highProteinThreshold
    }
    
    private var isLowFat: Bool {
        item.nutritionScores.fat <= lowFatThreshold
    }
    
    private var isLowCarbs: Bool {
        item.nutritionScores.carbs <= lowCarbsThreshold
    }
    
    var body: some View {
        MenuItemInfo(
            item: item,
            selectionManager: selectionManager,
            showHighProtein: showHighProtein,
            showLowFat: showLowFat,
            showLowCarbs: showLowCarbs,
            isHighProtein: isHighProtein,
            isLowFat: isLowFat,
            isLowCarbs: isLowCarbs
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MenuItemRow(
            item: MenuItem.sampleData[1],
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: true,
            selectionManager: SelectionManager()
        )
        
        MenuItemRow(
            item: MenuItem.sampleData[0],
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: true,
            selectionManager: SelectionManager()
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 
