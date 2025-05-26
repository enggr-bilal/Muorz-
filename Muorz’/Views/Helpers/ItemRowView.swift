//
//  ItemRowView.swift
//  Muorz’
//
//  Created by Simon Naud on 23/05/25.
//

import SwiftUI

struct ItemRowView: View {
    
    let originalName = "Ravioli Caprese"
    let translatedName = "Ravioli Capri"
    let descritpion = "Lettuce, radicchio, corn, olives, rocket and tiny mozzarella"
    let price = 12.00
    @State private var quantity = 2
    
    var body: some View {
        HStack{
            Rectangle()
                .frame(width: 6)
                .foregroundStyle(quantity > 0 ? .accent : .white)
            VStack(alignment: .leading){
                
                Text(translatedName)
                    .font(.system(size: 18, design: .serif))
                Spacer()
                Text(descritpion)
                    .font(.caption)
                    .foregroundStyle(.gray)
               
            }
            .frame(width: 250)
            .padding(.vertical)
            Spacer()
            VStack(alignment: .trailing){
                Text("\(price, specifier: "%.2f")€")
                    .font(.headline)
                Spacer()
                QuantityPickerView()
                
            }
            //.frame(width: 60)
            .padding(.vertical)
            
            
        }
        .frame(height: 100)
    }
}

#Preview {
    ItemRowView()
}
