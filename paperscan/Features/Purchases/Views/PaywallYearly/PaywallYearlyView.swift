// PurchaseView SwiftUI
// Created by Adam Lyttle on 7/18/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

// Special thanks:

//  --> Mario (https://x.com/marioapps_com) for recommending changes to fix
//      an issue Apple had rejecting the paywall due to excessive use of
//      the word "FREE"

import SwiftUI
import Inject

struct PaywallYearlyView: View {
    @ObserveInjection var inject
    
    @Environment(AppState.self) private var appState: AppState
    @State var purchaseModel: PaywallYearlyViewModel = PaywallYearlyViewModel()
    
    @State private var shakeDegrees = 0.0
    @State private var shakeZoom = 0.9
    @State private var showCloseButton = false
    @State private var progress: CGFloat = 0.0

    @Binding var isPresented: Bool
    
    @State var showNoneRestoredAlert: Bool = false
    @State private var showTermsActionSheet: Bool = false

    @State private var selectedProductId: String = ""
    
    let color: Color = Color.appPrimary
    
    private let allowCloseAfter: CGFloat = 5.0 //time in seconds until close is allows
    
    var hasCooldown: Bool = true
    
    let placeholderProductDetails: [PurchaseProductDetails] = []
    
    var callToActionText: String {
        guard let selectedProduct = purchaseModel.productDetails.first(where: { $0.productId == selectedProductId }) else {
            return "Unlock Now"
        }
        if selectedProduct.hasTrial {
            return "Start Free Trial"
        } else {
            return "Unlock Premium"
        }
    }
    
    var calculateFullPrice: Double? {
        if let weeklyPrice = purchaseModel.productDetails.first(where: {$0.duration == "week" || $0.duration == "Weekly"})?.price {
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency

            let weeklyPriceDouble = weeklyPrice
            return weeklyPriceDouble * 52
            
            
        }
        
        return nil
    }
    
    var calculatePercentageSaved: Int {
        if let calculateFullPrice = calculateFullPrice, let yearlyPrice = purchaseModel.productDetails.first(where: {$0.duration == "year" || $0.duration == "Annual"})?.price {
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency

            let yearlyPriceDouble = yearlyPrice
            
            let saved = Int(100 - ((yearlyPriceDouble / calculateFullPrice) * 100))
            
            if saved > 0 {
                return saved
            }

        }
        return 90
    }
    
    var body: some View {
        ZStack (alignment: .top) {
            
            ScrollView {
              VStack (spacing: 10) {
                  
                  ZStack (alignment: .top) {
                    Image("note")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100, alignment: .center)
                        .scaleEffect(shakeZoom)
                        .rotationEffect(.degrees(shakeDegrees))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                startShaking()
                            }
                        }

                    HStack {
                        Spacer()
                        
                        if hasCooldown && !showCloseButton {
                            Circle()
                                .trim(from: 0.0, to: progress)
                                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .opacity(0.1 + 0.1 * self.progress)
                                .rotationEffect(Angle(degrees: -90))
                                .frame(width: 20, height: 20)
                        }
                        else {
                            Image(systemName: "multiply")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, alignment: .center)
                                .clipped()
                                .onTapGesture {
                                    isPresented = false
                                }
                                .opacity(0.2)
                        }
                    }
                    .padding(.top)
                    .offset(x: -10, y: -10)
                    .zIndex(1)

                  }
                  
                  VStack (spacing: 10) {
                      Text("Unlock Premium Access")
                          .font(.system(size: 30, weight: .semibold))
                          .multilineTextAlignment(.center)
                      VStack (alignment: .leading) {
                          PurchaseFeatureView(title: "Unlimited scanning and recognition", icon: "camera.viewfinder", color: color)
                          PurchaseFeatureView(title: "Access detailed AI-powered analysis", icon: "sparkles", color: color)
                          PurchaseFeatureView(title: "Save and organize your scan history", icon: "rectangle.stack.fill", color: color)
                      }
                      .font(.system(size: 19))
                      .padding(.top)
                  }

                  Spacer()

                  VStack (spacing: 10) {
                      VStack (spacing: 10) {
                          
                          let productDetails = purchaseModel.isFetchingProducts ? placeholderProductDetails : purchaseModel.productDetails
                          
                          ForEach(productDetails) { productDetails in
                              
                              Button(action: {
                                  selectedProductId = productDetails.productId
                              }) {
                                  VStack {
                                      HStack {
                                          VStack(alignment: .leading) {
                                            HStack {
                                              Text(productDetails.duration + " Plan")
                                                  .font(.headline.bold())
                                                  .foregroundColor(.primary)

                                              if !productDetails.hasTrial {
                                                VStack {
                                                  Text("SAVE \(calculatePercentageSaved)%")
                                                      .font(.caption2.bold())
                                                      .foregroundColor(.white)
                                                      .padding(4)
                                                }
                                                .background(Color.red)
                                                .cornerRadius(6)   
                                              }
                                            }
                                            if productDetails.hasTrial {
                                                Text("\(productDetails.trialDuration ?? "Trial period"), then \(productDetails.priceString)")
                                                    .foregroundColor(.primary)
                                                    .opacity(0.8)
                                            }
                                            else {
                                                HStack (spacing: 0) {
                                                    if let calculateFullPrice = calculateFullPrice, //round down
                                                        let calculateFullPriceLocalCurrency = toLocalCurrencyString(calculateFullPrice),
                                                        calculateFullPrice > 0
                                                    {
                                                        //shows the full price based on weekly calculaation
                                                        Text("\(calculateFullPriceLocalCurrency) ")
                                                            .strikethrough()
                                                            .opacity(0.4)
                                                        
                                                    }
                                                    Text(" " + productDetails.priceString)
                                                        .foregroundColor(.primary)
                                                }
                                                .opacity(0.8)
                                            }
                                          }
                                          Spacer()
                                        
                                          ZStack {
                                              Image(systemName: (selectedProductId == productDetails.productId) ? "circle.fill" : "circle")
                                                  .foregroundColor((selectedProductId == productDetails.productId) ? color : Color.primary.opacity(0.15))
                                              
                                              if selectedProductId == productDetails.productId {
                                                  Image(systemName: "checkmark")
                                                      .foregroundColor(Color.white)
                                                      .scaleEffect(0.7)
                                              }
                                          }
                                          .font(.title3.bold())
                                          
                                      }
                                      .padding(.horizontal)
                                      .padding(.vertical, 10)
                                  }
                                  //.background(Color(.systemGray4))
                                  .cornerRadius(6)
                                  .overlay(
                                      ZStack {
                                          RoundedRectangle(cornerRadius: 6)
                                              .stroke((selectedProductId == productDetails.productId) ? color : Color.primary.opacity(0.15), lineWidth: 1) // Border color and width
                                          RoundedRectangle(cornerRadius: 6)
                                              .foregroundColor((selectedProductId == productDetails.productId) ? color.opacity(0.05) : Color.primary.opacity(0.001))
                                      }
                                  )
                              }
                              .accentColor(Color.primary)
                              
                          }
                          
                      }
                      .opacity(purchaseModel.isFetchingProducts ? 0 : 1)
                      
                      VStack (spacing: 25) {
                          
                          ZStack (alignment: .center) {
                              
                              //if purchasedModel.isPurchasing {
                              ProgressView()
                                  .opacity(purchaseModel.isPurchasing ? 1 : 0)
                              
                              Button(action: {
                                  //productManager.purchaseProduct()
                                  if !purchaseModel.isPurchasing {
                                      purchaseModel.purchaseSubscription(productId: self.selectedProductId)
                                  }
                              }) {
                                  HStack {
                                      Spacer()
                                      HStack {
                                          Text(callToActionText)
                                          Image(systemName: "chevron.right")
                                      }
                                      Spacer()
                                  }
                                  .padding()
                                  .foregroundColor(.white)
                                  .font(.title3.bold())
                              }
                              .background(color)
                              .cornerRadius(6)
                              .opacity(purchaseModel.isPurchasing ? 0 : 1)
                              .padding(.top)
                              .padding(.bottom, 4)
                              
                              
                          }
                          
                      }
                      .opacity(purchaseModel.isFetchingProducts ? 0 : 1)
                  }
                  .id("view-\(purchaseModel.isFetchingProducts)")
                  .background {
                      if purchaseModel.isFetchingProducts {
                          ProgressView()
                      }
                  }
                  
                  VStack (spacing: 5) {
                      
                      /*HStack (spacing: 4) {
                          Image(systemName: "figure.2.and.child.holdinghands")
                              .foregroundColor(Color.red)
                          Text("Family Sharing enabled")
                              .foregroundColor(.white)
                      }
                      .font(.footnote)*/
                      
                      HStack (spacing: 10) {
                          
                          Button("Restore Purchase") {
                              Task {
                                  await purchaseModel.restorePurchases()
                              }
                          }
                          .alert(isPresented: $showNoneRestoredAlert) {
                              Alert(title: Text("Restore Purchases"), message: Text("No purchases restored"), dismissButton: .default(Text("OK")))
                          }
                          .overlay(
                              Rectangle()
                                  .frame(height: 1)
                                  .foregroundColor(.gray), alignment: .bottom
                          )
                          .font(.footnote)

                          
                          Button("Terms of Use & Privacy Policy") {
                              showTermsActionSheet = true
                          }
                          .overlay(
                              Rectangle()
                                  .frame(height: 1)
                                  .foregroundColor(.gray), alignment: .bottom
                          )
                          .actionSheet(isPresented: $showTermsActionSheet) {
                              ActionSheet(title: Text("View Terms & Conditions"), message: nil,
                                          buttons: [
                                              .default(Text("Terms of Use (EULA)"), action: {
                                                if let url = URL(string: Constants.appleEulaUrl) {
                                                      UIApplication.shared.open(url)
                                                  }
                                              }),
                                              .default(Text("Privacy Policy"), action: {
                                                if let url = URL(string: Constants.privacyPolicyUrl) {
                                                      UIApplication.shared.open(url)
                                                  }
                                              }),
                                              .cancel()
                                          ])
                          }
                          .font(.footnote)
                          
                          
                      }
                      //.font(.headline)
                      .foregroundColor(.gray)
                      .font(.system(size: 15))
                      
                      
                      Text("Premium membership unlocks all the packs and content. This is an auto-renewal subscription. Subscriptions will automatically renew and you will be charged for renewal within 24 hours prior to end of each period unless auto renew is tuned off at least 24-hours before the end of each period. You can manage your subscription settings and auto-renewal may be turned off by going to Apple ID Account Settings after purchase.")
                          .font(.caption2)
                          .foregroundColor(.secondary)
                          .multilineTextAlignment(.center)
                          .padding(.top, 8)
                          .multilineTextAlignment(.center)
                          .fixedSize(horizontal: false, vertical: true)
                      
                      
                  }

                  Spacer()
                  
              }
          }
          .padding(.horizontal)
          .onChange(of: purchaseModel.productIds) { prods in
              if let trialProduct = purchaseModel.productDetails.first(where: { $0.hasTrial }) {
                  selectedProductId = trialProduct.productId
              } else if let firstProduct = prods.first {
                  selectedProductId = firstProduct
              } else {
                  selectedProductId = ""
              }
          }
        }
        .onAppear {
            // This block is for the initial setup when the view appears.
            // It should handle both the shaking animation and checking subscription status.

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeIn(duration: allowCloseAfter)) {
                    self.progress = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + allowCloseAfter) {
                    withAnimation {
                        showCloseButton = true
                    }
                }
            }
            
            // Start shaking animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Keep the original delay for shake
                startShaking()
            }
            
            // Check subscription status
            if purchaseModel.isSubscribed {
                isPresented = false
            }
        }
        .onChange(of: purchaseModel.isSubscribed) { isSubscribed in
            if(isSubscribed) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPresented = false
                }
            }
        }
        
        
    }
    
    private func startShaking() {
            let totalDuration = 0.7 // Total duration of the shake animation
            let numberOfShakes = 3 // Total number of shakes
            let initialAngle: Double = 10 // Initial rotation angle
            
            withAnimation(.easeInOut(duration: totalDuration / 2)) {
                self.shakeZoom = 0.95
                DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration / 2) {
                    withAnimation(.easeInOut(duration: totalDuration / 2)) {
                        self.shakeZoom = 0.9
                    }
                }
            }

            for i in 0..<numberOfShakes {
                let delay = (totalDuration / Double(numberOfShakes)) * Double(i)
                let angle = initialAngle - (initialAngle / Double(numberOfShakes)) * Double(i)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(Animation.easeInOut(duration: totalDuration / Double(numberOfShakes * 2))) {
                        self.shakeDegrees = angle
                    }
                    withAnimation(Animation.easeInOut(duration: totalDuration / Double(numberOfShakes * 2)).delay(totalDuration / Double(numberOfShakes * 2))) {
                        self.shakeDegrees = -angle
                    }
                }
            }

            // Stop the shaking and reset to 0
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                withAnimation {
                    self.shakeDegrees = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    startShaking()
                }
            }
        }
    
    
    struct PurchaseFeatureView: View {
    @ObserveInjection var inject
        
        let title: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 27, height: 27, alignment: .center)
                .clipped()
                .foregroundColor(color)
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
        }
    }

    func toLocalCurrencyString(_ value: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US") // Force USD
        return formatter.string(from: NSNumber(value: value))
    }

}

#Preview {
    PaywallYearlyView(isPresented: .constant(true))
        .tint(.appPrimary)
        .environment(AppState())
}
