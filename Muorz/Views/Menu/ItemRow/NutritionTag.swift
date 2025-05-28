//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct NutritionTag: View {
    let systemName: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .frame(height: 15)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

#Preview {
    HStack {
        NutritionTag(
            systemName: "figure.strengthtraining.traditional",
            label: "High Protein",
            color: .blue
        )
        NutritionTag(
            systemName: "leaf.fill",
            label: "Low Fat",
            color: .green
        )
        NutritionTag(
            systemName: "chart.line.downtrend.xyaxis",
            label: "Low Carbs",
            color: .orange
        )
    }
    .padding()
} 
