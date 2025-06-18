//
//  ScannedMenuCard.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct ScannedMenuCard: View {
    let menu: ScannedMenu
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with restaurant info and actions
                headerSection
                
                // Menu preview
                menuPreviewSection
                
                // Footer with metadata
                footerSection
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Restaurant info
            VStack(alignment: .leading, spacing: 4) {
                                    VStack(alignment: .leading) {
                        HStack {
                            TextField("Restaurant Name", text: Binding(
                                get: { menu.restaurantName ?? "" },
                                set: { menu.restaurantName = $0.isEmpty ? nil : $0 }
                            ))
                            .font(.system(.title2, design: .serif))
                            .fontWeight(.bold)
                            .textFieldStyle(PlainTextFieldStyle())
                            
                            
                            
                            // Actions - Only favorite button
                            Button(action: onFavorite) {
                                Image(systemName: menu.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(menu.isFavorite ? .red : .primary)
                                    .font(.title3)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        
                        if let rating = menu.rating, rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<Int(menu.rating ?? 0), id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                
                    if let cuisine = menu.restaurantCuisine {
                        Text(cuisine.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let location = menu.restaurantLocation {
                        HStack {
                            Image(systemName: "location")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                if let cuisine = menu.restaurantCuisine {
                    Text(cuisine.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
               
         
            
            
        }
    }
    
    // MARK: - Menu Preview Section
    
    private var menuPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Categories preview
            if !menu.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(menu.categories.prefix(3), id: \.self) { category in
                            Text(category.capitalized)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(6)
                        }
                        
                        if menu.categories.count > 3 {
                            Text("+\(menu.categories.count - 3)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Sample items
            VStack(alignment: .leading, spacing: 4) {
                ForEach(menu.menuItems.prefix(3), id: \.id) { item in
                    HStack {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(item.translatedName)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let price = item.price {
                            Text(price)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if menu.menuItems.count > 3 {
                    Text("... and \(menu.menuItems.count - 3) more dishes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
           
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(menu.scannedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(menu.menuItems.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "fork.knife")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Star Rating Component

struct StarRatingView: View {
    let rating: Int
    let maxRating: Int
    let onRatingChanged: ((Int) -> Void)?
    let isEditable: Bool
    
    init(rating: Int, maxRating: Int = 5, isEditable: Bool = false, onRatingChanged: ((Int) -> Void)? = nil) {
        self.rating = rating
        self.maxRating = maxRating
        self.isEditable = isEditable
        self.onRatingChanged = onRatingChanged
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Button(action: {
                    if isEditable {
                        onRatingChanged?(star)
                    }
                }) {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundColor(star <= rating ? .secondary : .gray)
                        .font(.system(size: 20))
                }
                .disabled(!isEditable)
            }
        }
    }
}

// MARK: - Menu Detail View

struct ScannedMenuDetailView: View {
    let menu: ScannedMenu
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditNotes = false
    @State private var notes: String
    @State private var rating: Int
    @State private var review: String
    @State private var isEditingRestaurantName = false
    @State private var tempRestaurantName: String = ""
    
    init(menu: ScannedMenu) {
        self.menu = menu
        self._notes = State(initialValue: menu.notes ?? "")
        self._rating = State(initialValue: menu.rating ?? 0)
        self._review = State(initialValue: menu.review ?? "")
        self._tempRestaurantName = State(initialValue: menu.restaurantName ?? "")
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content Section
                ScrollView {
                    VStack(spacing: 16) {
                        // Menu Items
                        MenuDetailListView(
                            menu: menu,
                            currency: menu.currency
                        )
                        
                        // Rating Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rate this menu")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            StarRatingView(
                                rating: rating,
                                isEditable: true
                            ) { newRating in
                                rating = newRating
                                menu.rating = newRating
                            }
                            
                            if rating > 0 {
                                Text("\(rating) out of 5 stars")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Review Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Review")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button("Save") {
                                    menu.review = review
                                }
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .disabled(review.isEmpty)
                            }
                            
                            TextEditor(text: $review)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Notes Section (if any)
                        if let notes = menu.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Notes")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button("Edit") {
                                        showingEditNotes = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                }
                                
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(menu.restaurantName?.isEmpty == false ? menu.restaurantName! : "Menu Details")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.primary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        menu.toggleFavorite()
                    } label: {
                        Label(menu.isFavorite ? "Remove from favorites" : "Add to favorites", 
                              systemImage: menu.isFavorite ? "heart.slash" : "heart")
                    }
                    
                    if menu.restaurantName?.isEmpty == false {
                        Button {
                            tempRestaurantName = menu.restaurantName ?? ""
                            isEditingRestaurantName = true
                        } label: {
                            Label("Edit restaurant name", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingEditNotes) {
            EditNotesView(notes: $notes, menu: menu)
        }
    }
}

struct MenuDetailListView: View {
    let menu: ScannedMenu
    let currency: String?
    
    // Helper function to sort categories in logical menu order
    private func sortedCategories() -> [String] {
        let categoryOrder = ["starter", "main course", "dessert", "drink", "other"]
        let availableCategories = Array(Set(menu.menuItems.map { $0.categoryEn }))
        
        // Sort based on logical order, then alphabetically for any unknown categories
        return availableCategories.sorted { first, second in
            let firstIndex = categoryOrder.firstIndex(of: first.lowercased()) ?? categoryOrder.count
            let secondIndex = categoryOrder.firstIndex(of: second.lowercased()) ?? categoryOrder.count
            
            if firstIndex != secondIndex {
                return firstIndex < secondIndex
            } else {
                // If both are unknown categories, sort alphabetically
                return first < second
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(sortedCategories(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.description.capitalized)
                            .font(.system(.title, design: .serif))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(menu.menuItems.filter { $0.categoryEn == category }, id: \.id) { item in
                                MenuItemDetailInfo(
                                    item: item,
                                    currency: currency
                                )
                                
                                if item.id != menu.menuItems.filter({ $0.categoryEn == category }).last?.id {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 80)
        }
    }
}

struct MenuItemDetailInfo: View {
    let item: PersistedMenuItem
    let currency: String?
    
    // Thresholds for nutritional tags (same as MenuItemRow)
    private let highProteinThreshold = 7
    private let lowFatThreshold = 3
    private let lowCarbsThreshold = 3
    
    private var isHighProtein: Bool {
        item.proteinScore >= highProteinThreshold
    }
    
    private var isLowFat: Bool {
        item.fatScore <= lowFatThreshold
    }
    
    private var isLowCarbs: Bool {
        item.carbsScore <= lowCarbsThreshold
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and Price row
            HStack(alignment: .top) {
                Text(item.translatedName)
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                if let price = item.price {
                    Text(price)
                        .font(.system(.title3, weight: .regular))
                        .foregroundColor(.black)
                        .fixedSize()
                }
            }
            
            // Description
            HStack(alignment: .top) {
                Text(item.ingredientsString)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                
                // Spacer to push ingredients to 3/4 width and leave space for price alignment
                Spacer(minLength: 80)
            }
            
            // Nutrition Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if isHighProtein {
                        NutritionTag(
                            systemName: "figure.strengthtraining.traditional",
                            label: "High Protein",
                            color: .blue
                        )
                    }
                    if isLowFat {
                        NutritionTag(
                            systemName: "leaf.fill",
                            label: "Low Fat",
                            color: .green
                        )
                    }
                    if isLowCarbs {
                        NutritionTag(
                            systemName: "chart.line.downtrend.xyaxis",
                            label: "Low Carbs",
                            color: .orange
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Supporting Views

struct EditNotesView: View {
    @Binding var notes: String
    let menu: ScannedMenu
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $notes)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .frame(maxHeight: 200)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        menu.notes = notes
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let sampleMenu = ScannedMenu(
        restaurantName: "Restaurant Test",
        restaurantCuisine: "Italien",
        restaurantLocation: "Paris, France",
        currency: "€",
        menuItems: [
            PersistedMenuItem(
                originalName: "Pizza Margherita",
                translatedName: "Margherita Pizza",
                ingredientsEn: ["tomato", "mozzarella", "basil"],
                categoryEn: "main course",
                price: "12.50",
                proteinScore: 6,
                fatScore: 5,
                carbsScore: 8,
                isVegetarian: true,
                isVegan: false,
                isGlutenFree: false,
                isDairyFree: false
            )
        ]
    )
    
    ScannedMenuCard(
        menu: sampleMenu,
        onTap: {},
        onFavorite: {},
        onDelete: {}
    )
    .padding()
} 
