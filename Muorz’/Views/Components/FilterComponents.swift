//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI
import Foundation

struct CategoryPicker: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(categories, id: \.self) { category in
                Text(category == "all" ? "All Categories" : category.capitalized)
                    .tag(category)
            }
        }
        .pickerStyle(.menu)
    }
}

struct DietFilterMenu: View {
    @Binding var selectedDietTag: String?
    
    var body: some View {
        Menu {
            Button(action: {
                selectedDietTag = nil
            }) {
                HStack {
                    Text("None")
                    if selectedDietTag == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            ForEach(FilterData.dietFilters) { filter in
                Button(action: {
                    selectedDietTag = filter.tag
                }) {
                    HStack {
                        Label(filter.name, systemImage: filter.icon)
                        if selectedDietTag == filter.tag {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "fork.knife.circle.fill")
                .foregroundColor(selectedDietTag != nil ? .green : .accentColor)
        }
    }
}

struct NutritionFilterMenu: View {
    @Binding var selectedNutritionTags: Set<String>
    
    var body: some View {
        Menu {
            ForEach(FilterData.nutritionFilters) { filter in
                Toggle(filter.name, isOn: Binding(
                    get: { selectedNutritionTags.contains(filter.tag) },
                    set: { isSelected in
                        if isSelected {
                            selectedNutritionTags.insert(filter.tag)
                        } else {
                            selectedNutritionTags.remove(filter.tag)
                        }
                    }
                ))
            }
            
            if !selectedNutritionTags.isEmpty {
                Divider()
                Button(role: .destructive, action: {
                    selectedNutritionTags.removeAll()
                }) {
                    Label("Clear Filters", systemImage: "xmark.circle.fill")
                }
            }
        } label: {
            Image(systemName: "tag.fill")
                .foregroundColor(selectedNutritionTags.isEmpty ? .accentColor : .green)
        }
    }
}

struct SelectedDietTag: View {
    let filter: DietFilter
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: filter.icon)
            Text(filter.name)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.green.opacity(0.8))
            }
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.15))
        .foregroundColor(.green)
        .cornerRadius(8)
    }
}
 
