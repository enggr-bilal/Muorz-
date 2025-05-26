struct FilterHeader: View {
    @Binding var selectedCategory: String
    @Binding var selectedDietTag: String?
    @Binding var selectedNutritionTags: Set<String>
    let categories: [String]
    
    private var selectedDietOption: PreferenceOption? {
        UserPreferences.dietaryOptions.first { $0.id == selectedDietTag }
    }
    
    private var selectedNutritionLabels: String {
        if selectedNutritionTags.isEmpty {
            return "Nutrition"
        }
        return selectedNutritionTags.count == 1 ? "1 Filter" : "\(selectedNutritionTags.count) Filters"
    }
    
    private var selectedCategoryLabel: String {
        selectedCategory == "all" ? "All" : selectedCategory.capitalized
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Categories Menu
                Menu {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            withAnimation {
                                selectedCategory = category
                            }
                        }) {
                            HStack {
                                Text(category == "all" ? "All Categories" : category.capitalized)
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterButton(
                        title: selectedCategoryLabel,
                        icon: "list.bullet",
                        isSelected: selectedCategory != "all"
                    )
                }
                
                // Diet Filter Button
                Menu {
                    Button(action: {
                        selectedDietTag = nil
                    }) {
                        HStack {
                            Text("No Preference")
                            if selectedDietTag == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    ForEach(UserPreferences.dietaryOptions) { option in
                        Button(action: {
                            selectedDietTag = option.id
                        }) {
                            HStack {
                                Text(option.name)
                                if selectedDietTag == option.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    if let dietOption = selectedDietOption {
                        FilterButton(
                            title: dietOption.name,
                            icon: "fork.knife",
                            isSelected: true
                        )
                    } else {
                        FilterButton(
                            title: "Diet",
                            icon: "fork.knife",
                            isSelected: false
                        )
                    }
                }
                
                // ... existing code ...
            }
        }
    }
} 