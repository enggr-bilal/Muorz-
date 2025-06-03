import Foundation

@MainActor
class OnboardingState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    
    private let onboardingCompletedKey = "hasCompletedOnboarding"
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: onboardingCompletedKey)
    }
} 