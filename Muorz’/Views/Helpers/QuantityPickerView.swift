//
//  QuantityPickerView.swift
//  Muorz’
//
//  Created by Simon Naud on 23/05/25.
//

import SwiftUI


struct QuantityPickerView: View {
    @State private var quantity = 2

    
    var body: some View {
        HStack{
            if quantity > 0 {
                if quantity == 1 {
                    Image(systemName: "trash")
                        .foregroundStyle(.accent)
                        .font(.title2)
                        .frame(width: 10, height: 50)
                        .onTapGesture {
                            quantity -= 1
                        }
                } else {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(.accent)
                        .font(.title2)
                        .frame(width: 10, height: 50)
                        .onTapGesture {
                            quantity -= 1
                        }
                }
                    Text("\(quantity)")
                    .frame(width: 30, height: 50)
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.accent)
                        .font(.title2)
                        .frame(width: 10, height: 50)
                        .onTapGesture {
                            quantity += 1
                        }
                
               
            } else {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.gray)
                    .font(.title2)
                    .frame(width: 20, height: 50)
                    .onTapGesture {
                        quantity += 1
                    }
                
            }
            
           
        }
        .frame(width: 80)
    }
}

#Preview {
    ItemRowView()
}
