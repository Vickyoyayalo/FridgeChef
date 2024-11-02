import SwiftUI
import Foundation

struct IngredientRow: View {
    @ObservedObject var viewModel: ChatViewModel

    var ingredient: ParsedIngredient
    var addAction: (ParsedIngredient) -> Bool
    var isInCart: Bool

    var body: some View {
        Button(action: {
            let success = addAction(ingredient)
            if success {
                viewModel.alertTitle = "Added to your Grocery List!"
                viewModel.alertMessage = "\(ingredient.name) added to your Grocery List 🛒"
                viewModel.showAlert = true
            }
            // If not successful, the accumulation alert is handled in ChatView
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                        .bold()
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    if ingredient.quantity > 0 {
                        Text("Qty: \(ingredient.quantity, specifier: "%.1f") \(ingredient.unit)")
                            .font(.custom("ArialRoundedMTBold", size: 15))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if isInCart {
                    Image(systemName: "cart.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "cart.badge.plus.fill")
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                }
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
