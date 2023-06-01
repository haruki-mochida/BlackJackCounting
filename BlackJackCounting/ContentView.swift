import SwiftUI

struct ContentView: View {
    @StateObject private var deck = DeckViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("Number of decks")
                    .frame(width: 100)
                    .padding(.trailing, -20) // Pickerに近づけるために右パディングをマイナスにします
                
                Picker("Number of decks", selection: $deck.deckCount) {
                    ForEach(1...8, id: \.self) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Spacer(minLength: 50) // 中央に寄せるためにSpacerの長さを調整します
                
                Text("Total Left: \(deck.totalCount)")
                    .frame(maxWidth: .infinity, alignment: .center) // テキストの位置を中央に調整します
            }
            
            ForEach(0..<2) { row in
                HStack {
                    ForEach(1..<6) { col in
                        let card = row * 5 + col
                        VStack {
                            Image("card_heart_\(card < 10 ? "0" : "")\(card)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 30)
                            Text("\(deck.cardsCount(card: card))")
                            Text(" \(deck.probability(card: card), specifier: "%.2f")")
                            //出現確率の色設定
                                .foregroundColor(getColorForProbability(card: card, probability: deck.probability(card: card)))
                        }
                        .padding()
                    }
                }
            }
            
            HStack{
                VStack {
                    HStack {
                        Image("card_heart_01")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 30)
                        Text("+")
                        Image("card_heart_10")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 30)
                    }
                    Text("BJ: \(deck.bjProbability, specifier: "%.2f")%")
                }
                
                Button(action: {
                    deck.reset()
                }) {
                    Text("Reset")
                }
                .alert(isPresented: $deck.showResetAlert) {
                    Alert(
                        title: Text("Reset Confirmation"),
                        message: Text("Do you really want to reset?"),
                        primaryButton: .default(Text("Yes"), action: deck.confirmReset),
                        secondaryButton: .cancel(Text("No"))
                    )
                }.padding()
                
                VStack {
                    HStack {
                        Image("card_heart_10")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 30)
                        Text("+")
                        Image("card_heart_10")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 30)
                    }
                    Text("20: \(deck.twentyProbability, specifier: "%.2f")%")
                }
            }
            
            Text("Bust (with the next card)")
                .padding(.leading)
            Spacer()
            
            HStack {
                ForEach(13...17, id: \.self) { score in
                    VStack {
                        Text("\(score)")
                        Text("\(String(format: "%.2f", deck.bustProbability(score: score) * 100))")
                        Text("%")
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.leading)
                }
            }
            
            VStack {
                ForEach(0..<3) { row in
                    HStack {
                        ForEach(1..<4) { col in
                            let card = row * 3 + col
                            Button(action: {
                                deck.decrementCard(card: card)
                            }) {
                                Text("\(card)")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.cyan)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            .padding()
            
            Button(action: {
                deck.decrementCard(card: 10)
            }) {
                Text("10/J/Q/K")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.cyan)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
    
    func getColorForProbability(card: Int, probability: Double) -> Color {
        if card == 10 {
            switch probability {
            case ...0.30: return .blue // 0.30以下なら青
            case 0.30..<0.33: return .black // 0.30以上0.33未満なら黒
            case 0.33..<0.34: return .yellow // 0.33以上0.34未満なら黄色
            case 0.34...: return .red // 0.34以上なら赤
            default: return .black // それ以外なら黒
            }
        } else {
            return .black // カードが10以外なら黒
        }
    }
    
    
    class DeckViewModel: ObservableObject {
        @Published var deckCount: Int = 1 {
            didSet {
                reset()
            }
        }
        @Published var showResetAlert: Bool = false
        
        private var cards: [Int: Int] = [:]
        
        init() {
            reset()
        }
        
        var totalCount: Int {
            cards.values.reduce(0, +)
        }
        
        func cardsCount(card: Int) -> Int {
            cards[card, default: 0]
        }
        
        func probability(card: Int) -> Double {
            guard totalCount > 0 else {
                return 0.0
            }
            return Double(cardsCount(card: card)) / Double(totalCount)
        }
        
        func bustProbability(score: Int) -> Double {
            let bustCards = cards.filter { $0.key > 21 - score }
            let bustCardsCount = bustCards.values.reduce(0, +)
            return Double(bustCardsCount) / Double(totalCount) }
        
        func decrementCard(card: Int) {
            guard let currentCount = cards[card], currentCount > 0 else {
                return
            }
            cards[card] = currentCount - 1
            objectWillChange.send()
        }
        
        func reset() {
            showResetAlert = true
        }
        
        func confirmReset() {
            cards = Array(repeating: 4 * deckCount, count: 10).enumerated().reduce(into: [:]) { result, element in
                // カードの値が10の場合は他のカードの4倍の枚数を設定
                let cardCount = (element.offset + 1 == 10) ? 4 * element.element : element.element
                result[element.offset + 1] = cardCount
            }
            showResetAlert = false
        }
        
        var bjProbability: Double {
            let aCount = cardsCount(card: 1)
            let tenCount = cardsCount(card: 10)
            return (Double(aCount) / Double(totalCount)) * (Double(tenCount) / Double(totalCount - 1)) * 2
        }
        
        var twentyProbability: Double {
            let tenCount = cardsCount(card: 10)
            return (Double(tenCount) / Double(totalCount)) * (Double(tenCount - 1) / Double(totalCount - 1))
        }
        
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View { ContentView()
            
        }
        
    }
    
}
