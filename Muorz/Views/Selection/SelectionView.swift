//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct SelectionView: View {
    @ObservedObject var selectionManager: SelectionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showTranslation = false
    @State private var showingWarningAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(selectionManager.selectedItems) { selectedItem in
                        SelectedItemRow(
                            selectedItem: selectedItem,
                            showTranslation: showTranslation,
                            onIncrement: { selectionManager.addItem(selectedItem.menuItem) },
                            onDecrement: { selectionManager.removeItem(selectedItem.menuItem) }
                        )
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                selectionManager.removeAllQuantities(selectedItem.menuItem)
                            } label: {
                                Label("Remove All", systemImage: "trash")
                            }
                        }
                    }
                    .padding()
                }
                
                if !selectionManager.selectedItems.isEmpty {
                    VStack(spacing: 16) {
                        Divider()
                        
                        if !showTranslation {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Total Items:")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(selectionManager.totalItems)")
                                        .font(.headline)
                                }
                                
                                HStack {
                                    Text("Estimated Amount:")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(String(format: "%.2f €", selectionManager.totalPrice))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal)
                            .transition(.opacity)
                        }
                        
                        Button(action: {
                            if !showTranslation {
                                // Show warning alert before showing original names
                                showingWarningAlert = true
                            } else {
                                // Switch back to selection view without warning
                                withAnimation(.spring()) {
                                    showTranslation = false
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: showTranslation ? "list.star" : "translate")
                                    .font(.system(size: 20))
                                Text(showTranslation ? "Show Selection" : "Show Original Names")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50) // Fixed height
                            .background(showTranslation ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule()) // Capsule shape
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color(UIColor.systemBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Selection")
                        .font(.system(.title2, design: .serif))
                        .accessibilityAddTraits(.isHeader)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectionManager.selectedItems.isEmpty {
                        Button(action: {
                            selectionManager.clearSelection()
                        }) {
                            Text("Clear All")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Warning", isPresented: $showingWarningAlert) {
                Button("Understood", role: .none) {
                    withAnimation(.spring()) {
                        showTranslation = true
                    }
                }
            } message: {
                Text("This app provides dietary suggestions, but cannot guarantee the absence of allergens. Please confirm with restaurant staff before ordering.")
            }
        }
    }
}
