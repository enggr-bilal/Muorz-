//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct NutritionTagsSection: View {
    let showHighProtein: Bool
    let showLowFat: Bool
    let showLowCarbs: Bool
    let isHighProtein: Bool
    let isLowFat: Bool
    let isLowCarbs: Bool
    
    var body: some View {
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
}

#Preview {
    NutritionTagsSection(
        showHighProtein: true,
        showLowFat: true,
        showLowCarbs: true,
        isHighProtein: true,
        isLowFat: true,
        isLowCarbs: true
    )
    .padding()
} 
