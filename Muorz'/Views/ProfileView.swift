struct ProfileView: View {
    @ObservedObject var preferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    UserInfoHeader(
                        userName: $preferences.userName,
                        onNameChange: { preferences.saveUserName() }
                    )
                }
                
                // Default Dietary Preference
                Section(header: Text("Default Dietary Preference"), footer: Text("Menus will be filtered to only show dishes that match your selected diets.")) {
                    DietaryPreferencePicker(selectedPreference: $preferences.defaultDietaryPreference)
                }
                .headerProminence(.increased)
                
                // Default Nutrition Labels
                Section(header: Text("Default Nutrition Labels"), footer: Text("Selected priorities will be displayed with badges to help you spot the right dishes faster.")) {
                    NutritionPreferenceToggles(
                        selectedPreferences: $preferences.defaultNutritionPreferences,
                        onPreferenceChange: { preferences.saveNutritionPreferences() }
                    )
                }
                .headerProminence(.increased)
                
                // Label Visibility Settings
                Section(header: Text("Label Visibility"), footer: Text("Toggle which nutrition labels you want to see on menu items.")) {
                    Toggle("Show High Protein Label", isOn: $preferences.showHighProteinLabel)
                    Toggle("Show Low Fat Label", isOn: $preferences.showLowFatLabel)
                    Toggle("Show Low Carbs Label", isOn: $preferences.showLowCarbsLabel)
                }
                .headerProminence(.increased)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Preferences")
                        .font(.system(.title2, design: .serif))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    // Handle logout
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

#Preview {
    ProfileView(preferences: UserPreferences())
} 