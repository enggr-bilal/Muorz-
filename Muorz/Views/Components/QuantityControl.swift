//
//  TEST.swift
//  Muorz’
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct QuantityControl: View {
    let quantity: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    // Constants
    private let maxQuantity = 99
    private let buttonSize: CGFloat = 24
    
    private var isAtMaxQuantity: Bool {
        quantity >= maxQuantity
    }
    
    var body: some View {
        HStack {
            Group {
                if quantity > 0 {
                    Button(action: onDecrement) {
                        Image(systemName: quantity == 1 ? "trash.circle" : "minus.circle")
                            .foregroundColor(quantity == 1 ? .red : .gray)
                            .font(.system(size: buttonSize))
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    Text("\(quantity)")
                        .fontWeight(.medium)
                        .frame(minWidth: 20)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.2), value: quantity)
            
            Button(action: onIncrement) {
                Image(systemName: quantity > 0 ? "plus.circle.fill" : "plus.circle")
                    .foregroundColor(isAtMaxQuantity ? .gray : (quantity > 0 ? .accentColor : .gray))
                    .font(.system(size: buttonSize))
            }
            .disabled(isAtMaxQuantity)
            .animation(.spring(response: 0.2), value: quantity)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        QuantityControl(
            quantity: 0,
            onIncrement: {},
            onDecrement: {}
        )
        
        QuantityControl(
            quantity: 1,
            onIncrement: {},
            onDecrement: {}
        )
        
        QuantityControl(
            quantity: 2,
            onIncrement: {},
            onDecrement: {}
        )
        
        QuantityControl(
            quantity: 99,
            onIncrement: {},
            onDecrement: {}
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
} 
