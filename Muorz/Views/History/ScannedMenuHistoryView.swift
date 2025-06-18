//
//  ScannedMenuHistoryView.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI
import SwiftData

struct ScannedMenuHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scannedMenuService: ScannedMenuService
    @StateObject private var preferences: UserPreferences
    
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var menuToDelete: ScannedMenu?
    @State private var selectedMenu: ScannedMenu? = nil
    
    // MARK: - Initialization
    
    init(preferences: UserPreferences) {
        self._preferences = StateObject(wrappedValue: preferences)
        // Initialize with a temporary context - will be replaced in onAppear
        self._scannedMenuService = StateObject(wrappedValue: ScannedMenuService.create(with: ModelContext(try! ModelContainer(for: ScannedMenu.self))))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                if scannedMenuService.isLoading {
                    loadingView
                } else if scannedMenuService.scannedMenus.isEmpty {
                    emptyStateView
                } else {
                    menuListView
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            
            ToolbarItem(placement: .principal) {
                Text("History")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(.primary)
            }
        }
        .searchable(text: $searchText, prompt: "Search menus...")
        .onChange(of: searchText) { _ in
            Task {
                await performSearch()
            }
        }
        .onAppear {
            scannedMenuService.updateModelContext(modelContext)
            Task {
                await scannedMenuService.loadScannedMenus()
            }
        }
        .refreshable {
            await scannedMenuService.loadScannedMenus()
        }
        .alert("Delete Menu", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let menu = menuToDelete {
                    Task {
                        try? await scannedMenuService.deleteScannedMenu(menu)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this menu? This action cannot be undone.")
        }
        .navigationDestination(item: $selectedMenu) { menu in
            ScannedMenuDetailView(menu: menu)
        }
    }
    
    // MARK: - Content Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading history...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No scanned menu")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Scan your first menu to start building your history")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Scan a menu") {
                // Navigate to camera view
                // This would need to be handled by the parent view
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var menuListView: some View {
        let filteredMenus = getFilteredMenus()
        
        return ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredMenus, id: \.id) { menu in
                    ScannedMenuCard(
                        menu: menu,
                        onTap: {
                            selectedMenu = menu
                        },
                        onFavorite: {
                            menu.toggleFavorite()
                            Task {
                                try? await scannedMenuService.updateScannedMenu(menu)
                            }
                        },
                        onDelete: {
                            menuToDelete = menu
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFilteredMenus() -> [ScannedMenu] {
        var filtered = scannedMenuService.scannedMenus
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.matchesSearchQuery(searchText) }
        }
        
        return filtered
    }
    
    private func performSearch() async {
        // Search is handled by the computed property
        // This method can be used for analytics or additional search logic
    }
}

#Preview {
    ScannedMenuHistoryView(preferences: UserPreferences())
        .modelContainer(for: ScannedMenu.self, inMemory: true)
} 
