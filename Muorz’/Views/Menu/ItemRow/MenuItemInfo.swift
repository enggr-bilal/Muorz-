//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct MenuItemInfo: View {
    let item: MenuItem
    @ObservedObject var selectionManager: SelectionManager
    let showHighProtein: Bool
    let showLowFat: Bool
    let showLowCarbs: Bool
    let isHighProtein: Bool
    let isLowFat: Bool
    let isLowCarbs: Bool
    
    private var quantity: Int {
        selectionManager.quantity(for: item)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and Price row
            HStack {
                Text(item.translatedName)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Spacer()
                
                Text(item.price ?? "N/A")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
            }
            
            // Description
            HStack {
                Text(item.ingredientsEn.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            // Tags and Quantity Control row
            
            Spacer()
            HStack {
                if showHighProtein || showLowFat || showLowCarbs {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if showHighProtein && isHighProtein {
                                NutritionTag(
                                    systemName: "figure.strengthtraining.traditional",
                                    label: "High Protein",
                                    color: .blue
                                )
                            }
                            if showLowFat && isLowFat {
                                NutritionTag(
                                    systemName: "leaf.fill",
                                    label: "Low Fat",
                                    color: .green
                                )
                            }
                            if showLowCarbs && isLowCarbs {
                                NutritionTag(
                                    systemName: "chart.line.downtrend.xyaxis",
                                    label: "Low Carbs",
                                    color: .orange
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                QuantityControl(
                    quantity: quantity,
                    onIncrement: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectionManager.addItem(item)
                    },
                    onDecrement: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectionManager.removeItem(item)
                    }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 130)
        .background(Color(UIColor.systemBackground))
        .animation(.spring(response: 0.2), value: quantity)
    }
}

#Preview {
    VStack(spacing: 20) {
        MenuItemInfo(
            item: MenuItem.sampleData[0],
            selectionManager: SelectionManager(),
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: true,
            isHighProtein: true,
            isLowFat: true,
            isLowCarbs: true
        )
        .background(Color.white)
        
        MenuItemInfo(
            item: MenuItem.sampleData[1],
            selectionManager: SelectionManager(),
            showHighProtein: true,
            showLowFat: true,
            showLowCarbs: true,
            isHighProtein: true,
            isLowFat: true,
            isLowCarbs: true
        )
        .background(Color.white)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 
