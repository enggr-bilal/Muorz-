import SwiftUI

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @ObservedObject var preferences: UserPreferences
    @ObservedObject var muorzManager: MuorzManager
    @State private var currentStep: Int = 1
    
    let onComplete: () -> Void
    
    var body: some View {
        TabView(selection: $currentStep) {
            // Screen 1: Welcome
            WelcomeScreen(
                onContinue: { currentStep = 2 }
            )
            .tag(1)
            
            // Screen 2: Diet Preferences
            DietPreferencesScreen(
                onboardingManager: onboardingManager,
                onContinue: { currentStep = 3 }
            )
            .tag(2)
            
            // Screen 3: Smart Tags
            SmartTagsScreen(
                onboardingManager: onboardingManager,
                onContinue: { currentStep = 4 }
            )
            .tag(3)
            
            // Screen 4: How It Works
            HowItWorksScreen(
                onContinue: { currentStep = 5 }
            )
            .tag(4)
            
            // Screen 5: Privacy
            PrivacyScreen(
                onContinue: { currentStep = 6 }
            )
            .tag(5)
            
            // Screen 6: Pricing Model
            PricingModelScreen(
                muorzManager: muorzManager,
                onContinue: { currentStep = 7 }
            )
            .tag(6)
            
            // Screen 7: Ready
            ReadyScreen(
                onboardingManager: onboardingManager,
                preferences: preferences,
                onComplete: onComplete
            )
            .tag(7)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea(.all)
        .onAppear {
            // 🧪 IMPORTANT: Reset all preferences at the start of onboarding
            resetPreferencesForFreshStart()
        }
    }
    
    /// Resets all user preferences to ensure clean onboarding experience
    private func resetPreferencesForFreshStart() {
        // Reset UserPreferences object
        preferences.defaultDietaryPreference = nil
        preferences.showHighProteinTag = true
        preferences.showLowFatTag = true
        preferences.showLowCarbsTag = true
        preferences.userName = ""
        
        // Clear UserDefaults to ensure persistence is reset
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "defaultDietaryPreference")
        defaults.set(true, forKey: "showHighProteinTag")
        defaults.set(true, forKey: "showLowFatTag")
        defaults.set(true, forKey: "showLowCarbsTag")
        defaults.set("", forKey: "userName")
        defaults.removeObject(forKey: "defaultNutritionSortPriority")
        
        // Reset onboarding manager state
        onboardingManager.resetToDefaults()
        
        print("🧪 Onboarding: All preferences reset for fresh start")
    }
}

// MARK: - Onboarding Manager

@MainActor
class OnboardingManager: ObservableObject {
    @Published var selectedDietPreferences: Set<DietPreference> = []
    @Published var enabledSmartTags: Set<SmartTag> = []
    
    enum DietPreference: String, CaseIterable, Identifiable {
        case vegetarian = "vegetarian"
        case vegan = "vegan"
        case glutenFree = "glutenFree"
        case dairyFree = "dairyFree"
        case none = "none"
        
        var id: String { rawValue }
        
        var emoji: String {
            switch self {
            case .vegetarian: return ""
            case .vegan: return ""
            case .glutenFree: return ""
            case .dairyFree: return ""
            case .none: return ""
            }
        }
        
        var title: String {
            switch self {
            case .vegetarian: return "Vegetarian"
            case .vegan: return "Vegan"
            case .glutenFree: return "Gluten-Free"
            case .dairyFree: return "Dairy-Free"
            case .none: return "None of these"
            }
        }
        
        var description: String {
            switch self {
            case .vegetarian: return "No meat or fish"
            case .vegan: return "No animal products at all"
            case .glutenFree: return "Avoids wheat and similar grains"
            case .dairyFree: return "No milk, cheese, or cream"
            case .none: return ""
            }
        }
    }
    
    enum SmartTag: String, CaseIterable, Identifiable {
        case highProtein = "high_protein"
        case lowFat = "low_fat"
        case lowCarbs = "low_carbs"
        
        var id: String { rawValue }
        
        var emoji: String {
            switch self {
            case .highProtein: return ""
            case .lowFat: return ""
            case .lowCarbs: return ""
            }
        }
        
        var title: String {
            switch self {
            case .highProtein: return "High Protein"
            case .lowFat: return "Low Fat"
            case .lowCarbs: return "Low Carbs"
            }
        }
        
        var description: String {
            switch self {
            case .highProtein: return "Fuel up"
            case .lowFat: return "Light and tasty"
            case .lowCarbs: return "Keep it simple"
            }
        }
    }
    
    func savePreferences(to userPreferences: UserPreferences) {
        // Save diet preferences with priority logic
        let selectedDiets = selectedDietPreferences.filter { $0 != .none }
        
        if selectedDiets.isEmpty || selectedDietPreferences.contains(.none) {
            // User selected "None" or nothing
            userPreferences.defaultDietaryPreference = nil
        } else {
            // Priority order: vegan > vegetarian > gluten_free > dairy_free
            let priorityOrder: [DietPreference] = [.vegan, .vegetarian, .glutenFree, .dairyFree]
            
            for preference in priorityOrder {
                if selectedDiets.contains(preference) {
                    userPreferences.defaultDietaryPreference = preference.rawValue
                    break
                }
            }
        }
        
        // Save smart tags
        userPreferences.showHighProteinTag = enabledSmartTags.contains(.highProtein)
        userPreferences.showLowFatTag = enabledSmartTags.contains(.lowFat)
        userPreferences.showLowCarbsTag = enabledSmartTags.contains(.lowCarbs)
        
        // Debug logging
        print("🧪 Onboarding saved:")
        print("   Diet preference: \(userPreferences.defaultDietaryPreference ?? "none")")
        print("   High Protein: \(userPreferences.showHighProteinTag)")
        print("   Low Fat: \(userPreferences.showLowFatTag)")
        print("   Low Carbs: \(userPreferences.showLowCarbsTag)")
    }
    
    func resetToDefaults() {
        selectedDietPreferences.removeAll()
        enabledSmartTags.removeAll()
    }
}

// MARK: - Base Components

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int = 7
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * (CGFloat(currentStep) / CGFloat(totalSteps)), height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
        .padding(.top, 60)
    }
}

struct OnboardingButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(style == .primary ? .white : .accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(style == .primary ? Color.accentColor : Color.clear)
                        .stroke(Color.accentColor, lineWidth: style == .secondary ? 2 : 0)
                )
        }
    }
}

// MARK: - Screen 1: Welcome

struct WelcomeScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 1)
                
                Spacer()
                
                VStack() {
                    
                    Spacer()
                    
                    VStack(spacing: 40) {
                        Text("Muorz")
                            .font(.system(size: 40, weight: .semibold, design: .serif))
                            .foregroundColor(.primary)
                           
                        Spacer()
                        
                        Text("Scan menus. Choose smarter. Eat freely.")
                            .font(.system(.title2, design: .serif))
                            .foregroundColor(.primary)
                        
                        Text("Discover local dishes, understand what you're ordering — and find what fits your diet. No stress. No guesswork.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        
                       
                        Spacer()
                    }
                    //.padding()
                }
               // .padding()
                
                Spacer()
                
                VStack(spacing: 16) {
                    OnboardingButton(
                        title: "Set Up My Preferences",
                        style: .primary,
                        action: onContinue
                    )
                    
                    Text("Curious about the name? *Muorz* means 'bite' in Neapolitan.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
               // .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Screen 2: Diet Preferences

struct DietPreferencesScreen: View {
    @ObservedObject var onboardingManager: OnboardingManager
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 2)
                
                Spacer()
                
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Do you follow a specific diet?")
                            .font(.system(.title2, design: .serif))
                            .foregroundColor(.primary)
                           // .multilineTextAlignment(.leading)
                        
                        Text("We'll personalize results based on your choices.")
                            .font(.body)
                           // .multilineTextAlignment(.leading)
                            .foregroundColor(.secondary)
                            
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(OnboardingManager.DietPreference.allCases) { preference in
                            DietPreferenceRow(
                                preference: preference,
                                isSelected: onboardingManager.selectedDietPreferences.contains(preference),
                                onTap: {
                                    if preference == .none {
                                        onboardingManager.selectedDietPreferences = [.none]
                                    } else {
                                        onboardingManager.selectedDietPreferences.remove(.none)
                                        if onboardingManager.selectedDietPreferences.contains(preference) {
                                            onboardingManager.selectedDietPreferences.remove(preference)
                                        } else {
                                            onboardingManager.selectedDietPreferences.insert(preference)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                OnboardingButton(
                    title: "Continue",
                    style: .primary,
                    action: onContinue
                )
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
    }
}

struct DietPreferenceRow: View {
    let preference: OnboardingManager.DietPreference
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                
                
                VStack(alignment: .leading) {
                    Text(preference.title)
                        .font(.system(size: 20, design: .serif))
             
                        .foregroundColor(.primary)
                    
                    if !preference.description.isEmpty {
                        Text(preference.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Image(systemName: "circle")
                        .foregroundStyle(Color.accentColor)
                        .font(.title2)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.title2)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Screen 3: Smart Tags

struct SmartTagsScreen: View {
    @ObservedObject var onboardingManager: OnboardingManager
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 3)
                
                Spacer()
                
                VStack( alignment: .leading, spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Want extra info on your dishes?")
                            .font(.system(.title2, design: .serif))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
           
                        
                        Text("We can highlight meals that are rich in protein, light in fat, or low in carbs.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        ForEach(OnboardingManager.SmartTag.allCases) { tag in
                            SmartTagToggle(
                                tag: tag,
                                isEnabled: onboardingManager.enabledSmartTags.contains(tag),
                                onToggle: {
                                    if onboardingManager.enabledSmartTags.contains(tag) {
                                        onboardingManager.enabledSmartTags.remove(tag)
                                    } else {
                                        onboardingManager.enabledSmartTags.insert(tag)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                OnboardingButton(
                    title: "Next",
                    style: .primary,
                    action: onContinue
                )
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
    }
}

struct SmartTagToggle: View {
    let tag: OnboardingManager.SmartTag
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tag.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(tag.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Screen 4: How It Works

struct HowItWorksScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 4)
                
                Spacer()
                
                VStack(spacing: 32) {
                    Text("Scan. Understand. Order.")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 24) {
                        HowItWorksStep(
                            icon: "📸",
                            title: "Scan any menu",
                            step: 1
                        )
                        
                        HowItWorksStep(
                            icon: "🌐",
                            title: "See translation + dietary match",
                            step: 2
                        )
                        
                        HowItWorksStep(
                            icon: "💬",
                            title: "Get a localized summary to order easily",
                            step: 3
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                OnboardingButton(
                    title: "Sounds Good",
                    style: .primary,
                    action: onContinue
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct HowItWorksStep: View {
    let icon: String
    let title: String
    let step: Int
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(icon)
                    .font(.title)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(step). \(title)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Screen 5: Privacy

struct PrivacyScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 5)
                
                Spacer()
                
                VStack(spacing: 32) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                    
                    VStack(spacing: 16) {
                        Text("Your data stays yours.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text("Menu scans are sent to an OCR service to process text — but your dietary preferences never leave your device.\n\nWe don't store, track, or sell anything. Ever.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                OnboardingButton(
                    title: "Continue",
                    style: .primary,
                    action: onContinue
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Screen 6: Pricing Model

struct PricingModelScreen: View {
    @ObservedObject var muorzManager: MuorzManager
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 6)
                
                Spacer()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Your first 3 scans are on the house.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text("3 scans/week for free")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        PricingOption(
                            title: "10 scans",
                            price: "€0.99",
                            isRecommended: false
                        )
                        
                        PricingOption(
                            title: "30 scans",
                            price: "€2.49",
                            isRecommended: true
                        )
                        
                        PricingOption(
                            title: "Unlimited 48h pass",
                            price: "€1.99",
                            isRecommended: false
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingButton(
                        title: "Continue with Free Plan",
                        style: .primary,
                        action: onContinue
                    )
                    
                    OnboardingButton(
                        title: "See Scan Packs",
                        style: .secondary,
                        action: {
                            // Open store
                        }
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct PricingOption: View {
    let title: String
    let price: String
    let isRecommended: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(price)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isRecommended ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                .stroke(isRecommended ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .overlay(
            isRecommended ? 
            VStack {
                HStack {
                    Text("RECOMMENDED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(4)
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
            : nil
        )
    }
}

// MARK: - Screen 7: Ready

struct ReadyScreen: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var preferences: UserPreferences
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                OnboardingProgressBar(currentStep: 7)
                
                Spacer()
                
                VStack(spacing: 32) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                    
                    VStack(spacing: 16) {
                        Text("Let's scan your first menu.")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text("We'll need access to your camera to start. Or you can try with a demo.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                VStack(spacing: 12) {
                    OnboardingButton(
                        title: "Enable Camera",
                        style: .primary,
                        action: {
                            onboardingManager.savePreferences(to: preferences)
                            onComplete()
                        }
                    )
                    
                    OnboardingButton(
                        title: "Try Demo Menu",
                        style: .secondary,
                        action: {
                            onboardingManager.savePreferences(to: preferences)
                            // Show demo
                            onComplete()
                        }
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        preferences: UserPreferences(),
        muorzManager: MuorzManager(),
        onComplete: {}
    )
} 
