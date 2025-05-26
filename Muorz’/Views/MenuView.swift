//
//  MenuView.swift
//  Muorz’
//
//  Created by Simon Naud on 23/05/25.
//

import SwiftUI

struct MenuView: View {
    
    var categories = ["Salads", "Pizze", "Dessert"]
    
    var body: some View {
        ForEach(categories, id: \.self) { categorie in
            Text(categorie)
                .font(.title3)
            
        }

    }
}

#Preview {
    MenuView()
}
