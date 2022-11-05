
import Foundation
import NearIOSWalletUIKit
import SwiftUI

struct HereButton: ButtonStyle {
    let color: Color
    init(color: Color = Color(NearIOSWalletUIKitAsset.Color.yellow.color)) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .circular)
                .fill(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color))
                .offset(.init(width: 6, height: 6))

            configuration.label
                .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color))
                .font(Font(NearIOSWalletUIKitFontFamily.Manrope.bold.font(size: 18)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .background(color)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .circular)
                    .stroke(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color), lineWidth: 1)
                )
                .offset(configuration.isPressed ? .init(width: 6, height: 6) : .zero)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
        .frame(height: 46)
    }
}

struct HereMainButton: ButtonStyle {
    let color: Color
    init(color: Color = Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color)) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.white)
            .font(Font(NearIOSWalletUIKitFontFamily.Manrope.bold.font(size: 18)))
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding(.horizontal, 16)
            .background(color)
            .cornerRadius(32)
            .scaleEffect(configuration.isPressed ? 0.95: 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}


struct InstantWallet: View {
    @ObservedObject
    var userSession: UserSession
    
    @State private var showExport = false
    
    var totalBalance: String {
        let usdFormatter = NumberFormatter()
        usdFormatter.numberStyle = .currency
        usdFormatter.currencySymbol = "$"
        
        let amount = userSession.nearToken?.fiatAmount ?? 0
        return usdFormatter.string(from: NSDecimalNumber(decimal: amount)) ?? ""
    }
    
    var tokens: [FtOverviewToken] {
        userSession.tokens.filter { $0.value > 0 || $0.symbol == "NEAR" }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(NearIOSWalletUIKitAsset.Color.elevation0.color)
            
            ScrollView {
                VStack {
                    HStack(alignment: .center, spacing: 8) {
                        Text(userSession.userProfile.account.address)
                            .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color))
                            .font(Font(NearIOSWalletUIKitFontFamily.Manrope.bold.font(size: 18)))
                            .truncationMode(.middle)
                            .lineLimit(1)
                        
                        Button(action: {
                            UIPasteboard.general.string = userSession.userProfile.account.address
                        }) {
                            Image(uiImage: NearIOSWalletUIKitAsset.Media.copy.image)
                        }
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .background(Color(NearIOSWalletUIKitAsset.Color.elevation1.color))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color), lineWidth: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total value")
                                .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackSecondary.color))
                                .font(Font(NearIOSWalletUIKitFontFamily.Manrope.medium.font(size: 14)))
                            
                            Text(totalBalance)
                                .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color))
                                .font(Font(NearIOSWalletUIKitFontFamily.CabinetGrotesk.black.font(size: 40)))
                        }
                        
                        VStack(alignment: .center, spacing: 16) {
                            HStack(alignment: .center, spacing: 16) {
                                Button(action: { showExport.toggle() }) {
                                    Text("+ Add money")
                                }
                                .buttonStyle(HereButton())
                                
                                Button(action: { showExport.toggle() }) {
                                    Text("↓ Withdraw")
                                }
                                .buttonStyle(HereButton())
                            }
                            
                            Button(action: { showExport.toggle() }) {
                                Text("Pay & Transfer")
                            }
                            .buttonStyle(HereButton(color: Color(NearIOSWalletUIKitAsset.Color.orange.color)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .padding(.bottom, 8)
                    .background(Color(NearIOSWalletUIKitAsset.Color.elevation1.color))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color), lineWidth: 1)
                    )
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(tokens, id: \.tokenId) { token in
                            HStack(alignment: .center) {
                                if let url = URL(string: token.icon) {
                                    if #available(iOS 15.0, *) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                            case .success(let image):
                                                image.resizable().transition(.scale(scale: 0.1, anchor: .center))
                                            case .failure:
                                                Image(systemName: "wifi.slash")
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(width: 40, height: 40)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(NearIOSWalletUIKitAsset.Color.blackDisabled.color))
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(token.name)
                                        .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color))
                                        .font(Font(NearIOSWalletUIKitFontFamily.Manrope.bold.font(size: 16)))
                                    
                                    Text("\(token.amount.rounded(scale: 2, roundingMode: .bankers).description) \(token.symbol)")
                                        .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackSecondary.color))
                                        .font(Font(NearIOSWalletUIKitFontFamily.Manrope.medium.font(size: 14)))
                                }
                                
                                Spacer()
               
                            }
                            .frame(height: 73)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .background(Color(NearIOSWalletUIKitAsset.Color.elevation1.color))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(16)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showExport, content: {
            ZStack {
                Color(NearIOSWalletUIKitAsset.Color.elevation0.color)
                    .edgesIgnoringSafeArea(.all)
                ExportWalletView(mnemonic: userSession.getMnemonic())
            }
        })
    }
}

struct ExportWalletView: View {
    let mnemonic: [String]
    
    var body: some View {
        ScrollView {
            Text("Export instant wallet")
                .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color))
                .font(Font(NearIOSWalletUIKitFontFamily.CabinetGrotesk.black.font(size: 32)))
                .padding(16)
                .padding(.top, 16)
            
            Text("""
            Write down or copy the following words in
            order and keep them somewhere safe.
            You will need them to enter the account
            after downloading the app.
            """)
            .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackSecondary.color))
            .font(Font(NearIOSWalletUIKitFontFamily.Manrope.medium.font(size: 16)))
            .multilineTextAlignment(.center)
            .padding(.bottom, 16)

            VStack {
                ForEach(mnemonic.chunked(into: 3), id: \.self) { chunk in
                    HStack {
                        ForEach(chunk, id: \.self) { word in
                            Text(word)
                                .foregroundColor(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color))
                                .font(Font(NearIOSWalletUIKitFontFamily.Manrope.bold.font(size: 16)))
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .background(Color(NearIOSWalletUIKitAsset.Color.elevation1.color))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(NearIOSWalletUIKitAsset.Color.blackPrimary.color), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(4)
            
            Button(action: {
                UIPasteboard.general.string = mnemonic.joined(separator: " ")
            }) {
                Text("Copy mnemonic phrase")
            }
            .buttonStyle(HereMainButton())
            .padding(.top, 32)
        }
        .padding(16)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
