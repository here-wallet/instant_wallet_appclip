import Foundation
import NearIOSWalletUIKit
import PanModal
import Combine
import UIKit

class MoneyFromLinkView: NiblessView {
    private let state: MoneyFromLinkModelState
    
    init(state: MoneyFromLinkModelState) {
        self.state = state
        super.init(frame: .zero)
        titleText.text = state.title
        subtitle.text = state.description
        sutupLayout()
    }
    
    func sutupLayout() {
        backgroundColor = NearIOSWalletUIKitAsset.Color.popupColor.color
        addSubview(titleText)
        addSubview(subtitle)
        addSubview(picture)
    
        NSLayoutConstraint.activate([
            picture.centerXAnchor.constraint(equalTo: centerXAnchor),
            picture.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -96),
            
            titleText.widthAnchor.constraint(equalTo: widthAnchor, constant: -32),
            titleText.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleText.topAnchor.constraint(equalTo: picture.bottomAnchor, constant: 32),
            subtitle.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitle.topAnchor.constraint(equalTo: titleText.bottomAnchor, constant: 16)
        ])
    }
    
    lazy var picture: UIView = {
        switch state {
        case .success:
            let image = UIImageView(image: NearIOSWalletUIKitAsset.Media.success.image)
            image.translatesAutoresizingMaskIntoConstraints = false
            image.contentMode = .scaleAspectFit
            image.heightAnchor.constraint(equalToConstant: 235).isActive = true
            return image

        case .failure:
            let image = UIImageView(image: NearIOSWalletUIKitAsset.Media.failure.image)
            image.translatesAutoresizingMaskIntoConstraints = false
            image.contentMode = .scaleAspectFit
            image.heightAnchor.constraint(equalToConstant: 235).isActive = true
            return image
            
        case .loading:
            let view = UIActivityIndicatorView(style: .large)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.startAnimating()
            return view
        }
    }()
    
    lazy var titleText: UILabel = {
        let label = UILabel()
        label.font = NearIOSWalletUIKitFontFamily.CabinetGrotesk.black.font(size: 32)
        label.textColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    lazy var subtitle: UILabel = {
        let label = UILabel()
        label.font = NearIOSWalletUIKitFontFamily.Manrope.regular.font(size: 16)
        label.textColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 4
        return label
    }()
}


extension MoneyFromLinkModelState {
    var title: String {
        switch self {
        case .success: return "Successfully"
        case .loading: return "Receiving the money..."
        case .failure: return "Failure"
        }
    }
        
    var description: String {
        switch self {
        case .success: return """
            All transfers are delivered, you can
            hide this screen and reload your balance
        """
            
        case .failure: return """
            Failed to get money. Looks like someone
            has already used this link.
        """
            
        case .loading: return """
            Requesting money using your link,
            please wait...
            """
        }
    }
}
