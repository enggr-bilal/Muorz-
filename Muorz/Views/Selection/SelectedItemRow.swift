//
//  TEST.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct SelectedItemRow: View {
    let selectedItem: SelectedItem
    let showTranslation: Bool
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack {
            if showTranslation {
                VStack(alignment: .leading, spacing: 8) {
                    
                        Text("\(selectedItem.quantity)×")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.accentColor)
                        
                        Text(selectedItem.menuItem.originalName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
            
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack(alignment: .leading) {
                    Text(selectedItem.menuItem.translatedName)
                        .font(.system(size: 18, design: .serif))
                    if let price = selectedItem.menuItem.price {
                        Text("\(price)")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
                .transition(.scale.combined(with: .opacity))
                
                Spacer()
                
                QuantityControl(
                    quantity: selectedItem.quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement
                )
            }
        }
        .padding(.vertical, 15)
    }
} 
