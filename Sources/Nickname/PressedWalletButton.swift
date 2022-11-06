import Foundation
import NearIOSWalletUIKit
import UIKit

open class PressedWalletButton: PressedUIButton {
    
    enum ButtonType {
        case filled(_ buttonColor: (UIColor, UIColor), _ titleColor: (UIColor, UIColor))
        case bordered(_ borderColor: UIColor, _ borderWidth: CGFloat)
    }
    
    enum SimpleButtonType {
        case simpleFilled(_ buttonColor: UIColor, _ titleColor: UIColor)
        case simpleBordered(_ borderColor: UIColor, _ borderWidth: CGFloat)
    }
    
    var buttonConfig: ButtonType
    
    override open var isEnabled: Bool {
        didSet {
            switch buttonConfig {
            case let .filled(buttonColor, titleColor):
                let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn)
                
                animator.addAnimations { [weak self] in
                    switch self?.isEnabled {
                    case true:
                        self?.backgroundColor = buttonColor.0
                        self?.setTitleColor(titleColor.0, for: .normal)
                    case false:
                        self?.backgroundColor = buttonColor.1
                        self?.setTitleColor(titleColor.1, for: .disabled)
                    default: break
                    }
                }
                
                animator.startAnimation()
            case .bordered: break
            }
        }
    }
    
    convenience init(
        buttonType: SimpleButtonType,
        action: UIAction? = nil
    ) {
        switch buttonType {
        case .simpleFilled(let buttonColor, let titleColor):
            let buttonType = ButtonType.filled(
                (buttonColor, buttonColor),
                (titleColor, titleColor)
            )
            self.init(buttonType: buttonType, action: action)
        case .simpleBordered(let borderColor, let borderWidth):
            let buttonType = ButtonType.bordered(borderColor, borderWidth)
            self.init(buttonType: buttonType, action: action)
        }
    }
    
    init(
        buttonType: ButtonType,
        action: UIAction? = nil
    ) {
        buttonConfig = buttonType
        let animatePair = PressedWalletButton.commonInit()
        super.init(touchBegan: animatePair.0, touchEnd: animatePair.1)
        if let action = action {
            self.addAction(action, for: .touchUpInside)
        }
        
        switch buttonType {
        case let .filled(buttonColor, titleColor):
            backgroundColor = buttonColor.0
            setTitleColor(titleColor.0, for: .normal)
        case let .bordered(borderColor, borderWidth):
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = borderWidth
            setTitleColor(NearIOSWalletUIKitAsset.Color.blackPrimary.color, for: .normal)
        }
    }
    
    private static func commonInit() -> (
        @MainActor (UIButton) async -> Void,
        @MainActor (UIButton) async -> Void
    ) {
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn)
        
        let animateIn: @MainActor (UIButton) async -> Void  = { @MainActor button in
            animator.addAnimations {
                button.transform = .init(scaleX: 0.93, y: 0.93)
            }
            animator.startAnimation()
            _ = await animator.addCompletion()
        }
        
        let animateOut: @MainActor (UIButton) async -> Void  = { @MainActor button in
            animator.addAnimations {
                button.transform = .identity
            }
            animator.startAnimation()
            _ = await animator.addCompletion()
        }
        
        return (animateIn, animateOut)
    }
}
