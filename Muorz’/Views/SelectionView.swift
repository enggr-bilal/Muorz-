//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct SelectionView: View {
    @ObservedObject var selectionManager: SelectionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showTranslation = false
    
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
               Spacer()
                
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
                                    Text("Total Amount:")
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
                            withAnimation(.spring()) {
                                showTranslation.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showTranslation ? "character.book.closed" : "character.book.closed.fill")
                                    .font(.system(size: 24))
                                Text(showTranslation ? "Show Prices" : "Show Original Names")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showTranslation ? Color.orange : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
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
                        .font(.system(.title2, design: .serif)) // Serif dynamique
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
           
                
              
                    }
                }
            }
      
