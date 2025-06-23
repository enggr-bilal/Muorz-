//
//  CameraView.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct DebugView: View {
    @ObservedObject var onboardingState: OnboardingState
    @ObservedObject var muorzManager: MuorzManager
    @ObservedObject var preferences: UserPreferences
    @State private var showingDemoMenu = false
    @State private var showDebugDuringProcessing = UserDefaults.standard.bool(forKey: "showDebugDuringProcessing")
    
    var body: some View {
        NavigationView {
            List {
                Section("🧪 Development Tools") {
                    Button("Reset Onboarding") {
                        resetOnboardingPreferences()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Reset Muorz to 0") {
                        muorzManager.remainingMuorz = 0
                        muorzManager.hasTravelDayPass = false
                        muorzManager.travelDayPassExpiryDate = nil
                        saveResetMuorzState()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Add Test Travel Pass") {
                        muorzManager.activateTravelDayPass()
                    }
                    .foregroundColor(.green)
                    
                    Button("Show Demo Menu") {
                        showingDemoMenu = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear All Preferences") {
                        clearAllPreferences()
                    }
                    .foregroundColor(.red)
                }
                
                Section("🔧 Debug Options") {
                    Toggle("Show Debug Info During Processing", isOn: $showDebugDuringProcessing)
                        .onChange(of: showDebugDuringProcessing) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "showDebugDuringProcessing")
                            print("🧪 Debug during processing: \(newValue ? "ON" : "OFF")")
                        }
                    
                    Text("When enabled, triple-tap during menu processing to see extracted text and logs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("📊 Current State") {
                    HStack {
                        Text("Onboarding Completed")
                        Spacer()
                        Text(onboardingState.hasCompletedOnboarding ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("Remaining Muorz")
                        Spacer()
                        Text("\(muorzManager.remainingMuorz)")
                    }
                    
                    HStack {
                        Text("Travel Pass Active")
                        Spacer()
                        Text(muorzManager.hasActiveTravelDayPass ? "✅" : "❌")
                    }
                    
                    if let dietPref = preferences.defaultDietaryPreference {
                        HStack {
                            Text("Diet Preference")
                            Spacer()
                            Text(dietPref)
                        }
                    } else {
                        HStack {
                            Text("Diet Preference")
                            Spacer()
                            Text("None set")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("High Protein Tag")
                        Spacer()
                        Text(preferences.showHighProteinTag ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("Low Fat Tag")
                        Spacer()
                        Text(preferences.showLowFatTag ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("Low Carbs Tag")
                        Spacer()
                        Text(preferences.showLowCarbsTag ? "✅" : "❌")
                    }
                }
                
                Section("💾 UserDefaults State") {
                    HStack {
                        Text("Diet in UserDefaults")
                        Spacer()
                        Text(UserDefaults.standard.string(forKey: "defaultDietaryPreference") ?? "none")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("High Protein in UD")
                        Spacer()
                        Text(UserDefaults.standard.bool(forKey: "showHighProteinTag") ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("Low Fat in UD")
                        Spacer()
                        Text(UserDefaults.standard.bool(forKey: "showLowFatTag") ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("Low Carbs in UD")
                        Spacer()
                        Text(UserDefaults.standard.bool(forKey: "showLowCarbsTag") ? "✅" : "❌")
                    }
                    
                    Button("Print All UserDefaults") {
                        printUserDefaultsState()
                    }
                    .foregroundColor(.purple)
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingDemoMenu) {
            DemoMenuView()
        }
    }
    
    private func resetOnboardingPreferences() {
        onboardingState.resetOnboarding()
        clearAllPreferences()
    }
    
    private func clearAllPreferences() {
        // Reset all user preferences to default state
        preferences.defaultDietaryPreference = nil
        preferences.showHighProteinTag = true
        preferences.showLowFatTag = true
        preferences.showLowCarbsTag = true
        preferences.userName = ""
        
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "defaultDietaryPreference")
        defaults.set(true, forKey: "showHighProteinTag")
        defaults.set(true, forKey: "showLowFatTag")
        defaults.set(true, forKey: "showLowCarbsTag")
        defaults.set("", forKey: "userName")
        
        print("🧪 All preferences cleared")
    }
    
    private func saveResetMuorzState() {
        let defaults = UserDefaults.standard
        defaults.set(0, forKey: "remainingMuorz")
        defaults.set(false, forKey: "hasTravelDayPass")
        defaults.removeObject(forKey: "travelDayPassExpiryDate")
        
        print("🧪 Muorz state reset to 0")
    }
    
    private func printUserDefaultsState() {
        print("💾 UserDefaults State:")
        print("Diet in UserDefaults: \(UserDefaults.standard.string(forKey: "defaultDietaryPreference") ?? "none")")
        print("High Protein in UD: \(UserDefaults.standard.bool(forKey: "showHighProteinTag") ? "✅" : "❌")")
        print("Low Fat in UD: \(UserDefaults.standard.bool(forKey: "showLowFatTag") ? "✅" : "❌")")
        print("Low Carbs in UD: \(UserDefaults.standard.bool(forKey: "showLowCarbsTag") ? "✅" : "❌")")
    }
}

// MARK: - Demo Menu View

struct DemoMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var menuViewModel = MenuViewModel()
    @StateObject private var preferences = UserPreferences()
    
    var body: some View {
        NavigationView {
            MenuView(viewModel: menuViewModel, preferences: preferences)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Demo Menu")
                            .font(.headline)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            loadDemoData()
        }
    }
    
    private func loadDemoData() {
        let demoItems = createDemoMenuItems()
        menuViewModel.menuItems = demoItems
        menuViewModel.restaurantInfo = RestaurantInfo(
            name: "Demo Restaurant",
            cuisine: "Italian",
            location: "Demo City"
        )
        menuViewModel.initializeWithDefaults(from: preferences)
    }
}

// MARK: - Demo Data Creation

func createDemoMenuItems() -> [MenuItem] {
    return [
        // Starters
        MenuItem(
            originalName: "BRUSCHETTA VEGETARIANA",
            translatedName: "Vegetarian Bruschetta",
            ingredientsEn: ["tomato", "basil", "mozzarella", "bread"],
            categoryEn: "starter",
            price: "8,00 €",
            nutritionScores: NutritionScores(protein: 4, fat: 5, carbs: 7),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
        ),
        
        MenuItem(
            originalName: "MINI POIVRONS FARCIS AU THON",
            translatedName: "Mini Peppers Stuffed with Tuna",
            ingredientsEn: ["mini peppers", "tuna", "olive oil", "herbs"],
            categoryEn: "starter",
            price: "6,00 €",
            nutritionScores: NutritionScores(protein: 6, fat: 5, carbs: 2),
            tags: DietaryTags(vegetarian: false, vegan: false, glutenFree: true, dairyFree: true)
        ),
        
        // Main Courses
        MenuItem(
            originalName: "PIZZA VEGETARIANA",
            translatedName: "Vegetarian Pizza",
            ingredientsEn: ["tomato sauce", "mushrooms", "bell peppers", "mozzarella"],
            categoryEn: "main course",
            price: "12,00 €",
            nutritionScores: NutritionScores(protein: 5, fat: 6, carbs: 8),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
        ),
        
        MenuItem(
            originalName: "PASTA ALLA BOLOGNESE",
            translatedName: "Bolognese Pasta",
            ingredientsEn: ["pasta", "ground beef", "tomato sauce", "onions"],
            categoryEn: "main course",
            price: "11,00 €",
            nutritionScores: NutritionScores(protein: 7, fat: 6, carbs: 8),
            tags: DietaryTags(vegetarian: false, vegan: false, glutenFree: false, dairyFree: true)
        ),
        
        MenuItem(
            originalName: "RISOTTO AI FUNGHI",
            translatedName: "Mushroom Risotto",
            ingredientsEn: ["arborio rice", "mushrooms", "parmesan", "white wine"],
            categoryEn: "main course",
            price: "13,00 €",
            nutritionScores: NutritionScores(protein: 4, fat: 5, carbs: 7),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: true, dairyFree: false)
        ),
        
        MenuItem(
            originalName: "SALMONE GRIGLIATO",
            translatedName: "Grilled Salmon",
            ingredientsEn: ["salmon", "lemon", "herbs", "vegetables"],
            categoryEn: "main course",
            price: "16,00 €",
            nutritionScores: NutritionScores(protein: 8, fat: 4, carbs: 2),
            tags: DietaryTags(vegetarian: false, vegan: false, glutenFree: true, dairyFree: true)
        ),
        
        // Desserts
        MenuItem(
            originalName: "TIRAMISU",
            translatedName: "Tiramisu",
            ingredientsEn: ["ladyfingers", "mascarpone", "coffee", "cocoa"],
            categoryEn: "dessert",
            price: "5,00 €",
            nutritionScores: NutritionScores(protein: 3, fat: 7, carbs: 6),
            tags: DietaryTags(vegetarian: true, vegan: false, glutenFree: false, dairyFree: false)
        ),
        
        MenuItem(
            originalName: "GELATO VEGAN",
            translatedName: "Vegan Ice Cream",
            ingredientsEn: ["coconut milk", "vanilla", "sugar"],
            categoryEn: "dessert",
            price: "4,00 €",
            nutritionScores: NutritionScores(protein: 1, fat: 3, carbs: 5),
            tags: DietaryTags(vegetarian: true, vegan: true, glutenFree: true, dairyFree: true)
        )
    ]
}

#Preview {
    DebugView(
        onboardingState: OnboardingState(),
        muorzManager: MuorzManager(),
        preferences: UserPreferences()
    )
} 
