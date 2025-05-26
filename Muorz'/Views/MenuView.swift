struct MenuView: View {
    let menuItems = MenuItem.sampleData
    @StateObject private var selectionManager = SelectionManager()
    @State private var selectedCategory: String = "all"
    @ObservedObject var preferences: UserPreferences
    @State private var showingSelection = false
    @State private var showingProfile = false
    
    var categories: [String] {
        ["all"] + Array(Set(menuItems.map { $0.categoryEn })).sorted()
    }
    
    // Constants for nutritional thresholds
    private let highProteinThreshold = 6
    private let lowFatThreshold = 5
    private let lowCarbsThreshold = 4
    
    var filteredItems: [String: [MenuItem]] {
        // First, filter by category
        let categoryFiltered = selectedCategory == "all" ? menuItems : menuItems.filter { $0.categoryEn == selectedCategory }
        
        // Then, filter by dietary preferences
        let dietFiltered = preferences.defaultDietaryPreference == nil ? categoryFiltered : categoryFiltered.filter { item in
            switch preferences.defaultDietaryPreference {
            case "vegetarian": return item.tags.vegetarian
            case "vegan": return item.tags.vegan
            case "glutenFree": return item.tags.glutenFree
            case "dairyFree": return item.tags.dairyFree
            default: return true
            }
        }
        
        // Finally, filter by nutrition preferences
        let nutritionFiltered = dietFiltered.filter { item in
            // If no nutrition filters are selected, show all items
            guard !preferences.defaultNutritionPreferences.isEmpty else { return true }
            
            // Check each selected nutrition filter
            for filter in preferences.defaultNutritionPreferences {
                switch filter {
                case "protein":
                    if item.nutritionScores.protein >= highProteinThreshold { return true }
                case "fat":
                    if item.nutritionScores.fat <= lowFatThreshold { return true }
                case "carbs":
                    if item.nutritionScores.carbs <= lowCarbsThreshold { return true }
                default:
                    continue
                }
            }
            return false
        }
        
        return Dictionary(grouping: nutritionFiltered) { $0.categoryEn }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    FilterHeader(
                        selectedCategory: $selectedCategory,
                        selectedDietTag: Binding(
                            get: { preferences.defaultDietaryPreference },
                            set: { preferences.defaultDietaryPreference = $0 }
                        ),
                        selectedNutritionTags: Binding(
                            get: { preferences.defaultNutritionPreferences },
                            set: { preferences.defaultNutritionPreferences = $0 }
                        ),
                        categories: categories
                    )
                    
                    // Menu List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredItems.keys.sorted(), id: \.self) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(category.description.capitalized)
                                        .font(.system(size: 24, weight: .regular, design: .serif))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                    
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(filteredItems[category] ?? []) { item in
                                            MenuItemRow(
                                                item: item,
                                                showHighProtein: preferences.showHighProteinLabel,
                                                showLowFat: preferences.showLowFatLabel,
                                                showLowCarbs: preferences.showLowCarbsLabel,
                                                selectionManager: selectionManager
                                            )
                                            
                                            if item.id != filteredItems[category]?.last?.id {
                                                Divider()
                                                    .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .padding(.bottom, 80) // Add padding at the bottom for the floating button
                    }
                }
                
                // Floating Cart Button
                if selectionManager.totalItems > 0 {
                    FloatingCartButton(
                        itemCount: selectionManager.totalItems,
                        action: { showingSelection = true }
                    )
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Menu")
                        .font(.system(.title2, design: .serif))
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSelection) {
                SelectionView(selectionManager: selectionManager)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(preferences: preferences)
            }
        }
    }
}

#Preview {
    MenuView(preferences: UserPreferences())
} 