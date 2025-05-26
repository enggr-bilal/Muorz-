//
//  FloatingCartButton.swift
//  Muorz'
//
//  Created by Simon Naud on 26/05/25.
//

import SwiftUI

struct FloatingCartButton: View {
    let itemCount: Int
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Button(action: action) {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("\(itemCount)")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        FloatingCartButton(itemCount: 3) {}
    }
} 