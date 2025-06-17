import SwiftUI

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @ObservedObject var preferences: UserPreferences
    @ObservedObject var muorzManager: MuorzManager
    @State private var currentStep: Int = 1
    @State private var isGoingForward: Bool = true
    
    let onComplete: () -> Void
    
    var body: some View {
        Group {
            if currentStep == 1 {
                // Special full-screen welcome view
                WelcomeScreen(
                    onContinue: {
                        isGoingForward = true
                        currentStep = 2
                    }
                )
            } else {
                // Standard onboarding structure for other screens
                StandardOnboardingView(
                    currentStep: $currentStep,
                    isGoingForward: $isGoingForward,
                    onboardingManager: onboardingManager,
                    muorzManager: muorzManager,
                    preferences: preferences,
                    onComplete: onComplete
                )
            }
        }
        .onAppear {
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

// MARK: - Welcome Screen (Full Screen)

struct WelcomeScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Background image
            Image("Onboarding")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Semi-transparent overlay to ensure text readability
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Centered content area
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 40) {
                        Text("Muorz")
                            .font(.system(size: 48, weight: .semibold, design: .serif))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                           
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Scan menus. Choose smarter. Eat freely.")
                                .font(.system(.title2, design: .serif))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .multilineTextAlignment(.leading)
                            
                            Text("Discover local dishes, understand what you're ordering — and find what fits your diet. No stress. No guesswork.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                VStack(spacing: 16) {
                    OnboardingButton(
                        title: "Set Up My Preferences",
                        style: .primary,
                        action: onContinue,
                        isDisabled: false
                    )
                    
                    Text("Curious about the name? *Muorz* means 'bite' in Neapolitan.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
            .padding()
        }
    }
}

// MARK: - Standard Onboarding View (Screens 2-7)

struct StandardOnboardingView: View {
    @Binding var currentStep: Int
    @Binding var isGoingForward: Bool
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var muorzManager: MuorzManager
    @ObservedObject var preferences: UserPreferences
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Fixed Header
                VStack(spacing: 0) {
                    // Back button
                    HStack {
                        Button(action: {
                            isGoingForward = false
                            currentStep -= 1
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.leading, 20)
                        //.padding(.top, 20)
                        
                        Spacer()
                    }
                    
                    // Progress bar
                    OnboardingProgressBar(currentStep: currentStep)
                }
                
                // Scrollable Content Area
                ScrollView {
                    VStack(spacing: 0) {
                        Group {
                            switch currentStep {
                            case 2:
                                DietPreferencesContent(onboardingManager: onboardingManager)
                            case 3:
                                SmartTagsContent(onboardingManager: onboardingManager)
                            case 4:
                                HowItWorksContent()
                            case 5:
                                PrivacyContent()
                            case 6:
                                PricingModelContent(muorzManager: muorzManager)
                            case 7:
                                ReadyContent(onboardingManager: onboardingManager, preferences: preferences)
                            default:
                                DietPreferencesContent(onboardingManager: onboardingManager)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: isGoingForward ? .trailing : .leading),
                            removal: .move(edge: isGoingForward ? .leading : .trailing)
                        ))
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                
                // Fixed Footer with CTA
                VStack(spacing: 16) {
                    OnboardingButton(
                        title: getCTATitle(),
                        style: .primary,
                        action: handleCTAAction,
                        isDisabled: isButtonDisabled()
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .background(Color(.systemGray6))
            }
        }
    }
    
    private func getCTATitle() -> String {
        switch currentStep {
        case 2: return "Continue"
        case 3: return "Next"
        case 4: return "Sounds Good"
        case 5: return "Continue"
        case 6: return "Continue with Free Plan"
        case 7: return "Enable Camera"
        default: return "Continue"
        }
    }
    
    private func isButtonDisabled() -> Bool {
        switch currentStep {
        case 2:
            // Disable if no diet preference is selected
            return onboardingManager.selectedDietPreferences.isEmpty
        default:
            return false
        }
    }
    
    private func handleCTAAction() {
        // Don't proceed if button is disabled
        if isButtonDisabled() {
            return
        }
        
        switch currentStep {
        case 2:
            isGoingForward = true
            currentStep = 3
        case 3:
            isGoingForward = true
            currentStep = 4
        case 4:
            isGoingForward = true
            currentStep = 5
        case 5:
            isGoingForward = true
            currentStep = 6
        case 6:
            isGoingForward = true
            currentStep = 7
        case 7:
            onboardingManager.savePreferences(to: preferences)
            onComplete()
        default:
            break
        }
    }
}

// MARK: - Content Views (Scrollable Content Only)

struct WelcomeContent: View {
    var body: some View {
        ZStack {
            // Background image
            Image("Onboarding")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Semi-transparent overlay to ensure text readability
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 40) {
                
                
                VStack(alignment: .leading, spacing: 40) {
                    Spacer()
                    Text("Muorz")
                        .font(.system(size: 48, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .multilineTextAlignment(.leading)
                       
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scan menus. Choose smarter. Eat freely.")
                            .font(.system(.title2, design: .serif))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                        
                        Text("Discover local dishes, understand what you're ordering — and find what fits your diet. No stress. No guesswork.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                
                
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 60)
        }
    }
}

struct DietPreferencesContent: View {
    @ObservedObject var onboardingManager: OnboardingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Do you follow a specific diet?")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text("We'll personalize results based on your choices.")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(OnboardingManager.DietPreference.allCases) { preference in
                    DietPreferenceRow(
                        preference: preference,
                        isSelected: onboardingManager.selectedDietPreferences.contains(preference),
                        onTap: {
                            if onboardingManager.selectedDietPreferences.contains(preference) {
                                onboardingManager.selectedDietPreferences.removeAll()
                            } else {
                                onboardingManager.selectedDietPreferences.removeAll()
                                onboardingManager.selectedDietPreferences.insert(preference)
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

struct SmartTagsContent: View {
    @ObservedObject var onboardingManager: OnboardingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Want extra info on your dishes?")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text("We can highlight meals that are rich in protein, light in fat, or low in carbs.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
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
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

struct HowItWorksContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Scan. Understand. Order.")
                .font(.system(.title2, design: .serif))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
              
            VStack(alignment: .leading, spacing: 32) {
                HowItWorksStep(
                    icon: "camera.fill",
                    title: "Scan any menu",
                    step: "Snap a photo — we'll handle the language and layout."
                )
                HowItWorksStep(
                    icon: "translate",
                    title: "Explore your options",
                    step: "See what matches your diet, with tags and filters that make sense to you."
                )
                HowItWorksStep(
                    icon: "list.bullet",
                    title: "Order with confidence",
                    step: "Show the dish name in the original language — no guesswork, no surprises."
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

struct PrivacyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your data stays yours.")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text("We scan menus locally on your phone. Then, a smart language model helps structure the text — without ever linking it to you.")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                Text("Your diet preferences stay on your device. We don't track, store, or sell anything. Ever.")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 150))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

struct PricingModelContent: View {
    @ObservedObject var muorzManager: MuorzManager
    @State private var animatedMuorzCount: Int = 3
    @State private var circleScale: CGFloat = 1.0
    @State private var hasStartedAnimation = false
    @State private var isPulseMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Just enough to get you started")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.primary)
                
                Text("You get 3 free Muorz every week — no sign-up, no stress. And as a welcome gift, here's 2 extra on us.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Large Muorz Counter
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 90, height: 90)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    if animatedMuorzCount <= 50 {
                        Image(systemName: "\(animatedMuorzCount).circle.fill")
                            .font(.system(size: 120, weight: .bold))
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 90, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                }
                .scaleEffect(circleScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: circleScale)
                .scaleEffect(isPulseMode ? 1.10 : 1.0)
                .animation(
                    isPulseMode ? 
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                    .default, 
                    value: isPulseMode
                )
                
                Spacer()
            }
            
            // Description text
            VStack(alignment: .center, spacing: 14) {
                Text("Muorz")
                    .font(.system(.title, design: .serif))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("A Muorz is a token that unlocks one menu scan — translated, explained, and tailored to you.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text("As a welcome gift, here's 2 extra on us.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startWelcomeBonusAnimation()
            }
        }
    }
    
    private func startWelcomeBonusAnimation() {
        guard !hasStartedAnimation else { return }
        hasStartedAnimation = true
        
        animateToNextMuorz(from: 3, to: 4) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateToNextMuorz(from: 4, to: 5) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.isPulseMode = true
                    }
                }
            }
        }
    }
    
    private func animateToNextMuorz(from: Int, to: Int, completion: @escaping () -> Void) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            circleScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            animatedMuorzCount = to
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                circleScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion()
            }
        }
    }
}

struct ReadyContent: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var preferences: UserPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Let's scan your first menu.")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text("We'll need access to your camera to start.")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
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
        .padding(.top, 20)
    }
}

struct OnboardingButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    let isDisabled: Bool
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(buttonTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(buttonBackgroundColor)
                        .stroke(buttonBorderColor, lineWidth: style == .secondary ? 2 : 0)
                )
        }
        .disabled(isDisabled)
    }
    
    private var buttonTextColor: Color {
        if isDisabled {
            return .gray
        }
        return style == .primary ? .white : .accentColor
    }
    
    private var buttonBackgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.2)
        }
        return style == .primary ? Color.accentColor : Color.clear
    }
    
    private var buttonBorderColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        }
        return Color.accentColor
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
                    .fill(Color.white)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SmartTagToggle: View {
    let tag: OnboardingManager.SmartTag
    let isEnabled: Bool
    let onToggle: () -> Void
    
    private var nutritionTagData: (systemName: String, color: Color) {
        switch tag {
        case .highProtein:
            return ("figure.strengthtraining.traditional", .blue)
        case .lowFat:
            return ("leaf.fill", .green)
        case .lowCarbs:
            return ("chart.line.downtrend.xyaxis", .orange)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                // NutritionTag component
                NutritionTag(
                    systemName: nutritionTagData.systemName,
                    label: tag.title,
                    color: nutritionTagData.color
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
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
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct HowItWorksStep: View {
    let icon: String
    let title: String
    let step: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .serif))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(step)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
