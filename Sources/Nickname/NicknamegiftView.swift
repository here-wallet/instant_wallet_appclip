import NearIOSWalletUIKit
import UIKit
import Combine

final class NicknameGiftView: NiblessView {
    
    enum Button {
        case skip
        case `continue`
    }
    
    public var buttonPublisher: AnyPublisher<Button, Never> {
        buttonSubject.eraseToAnyPublisher()
    }
    
    public var textfieldPublisher: AnyPublisher<String?, Never> {
        textField.textPublisher
    }
    
    public var continueButton: UIButton {
        buttonStack.arrangedSubviews[1] as! UIButton
    }
    
    private var loader: OverlayLoader = {
        let view = OverlayLoader(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    private var alreadyMoved: Bool = false
    private let buttonSubject: PassthroughSubject<Button, Never> = .init()
    
    private var bottomConstraint: NSLayoutConstraint! = nil
    
    private var bgView: UIView = {
        let view = NiblessView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        view.layer.cornerRadius = 16
        return view
    }()
    
    private var nicknameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Nickname"
        label.textColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        label.font = NearIOSWalletUIKitFontFamily.CabinetGrotesk.black.font(size: 32)
        return label
    }()
    
    private var freeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "FREE"
        label.textColor = NearIOSWalletUIKitAsset.Color.green.color
        label.font = NearIOSWalletUIKitFontFamily.CabinetGrotesk.black.font(size: 32)
        
        return label
    }()
    
    private var overlayLine: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        return view
    }()
    
    private var priceLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = NearIOSWalletUIKitAsset.Color.blackDisabled.color
        label.text = "0.1 NEAR"
        label.font = NearIOSWalletUIKitFontFamily.CabinetGrotesk.extrabold.font(size: 16)
        return label
    }()
    
    private var descriptionStack: UIStackView = {
        let label = UILabel(frame: .zero)
        let image = NearIOSWalletUIKitAsset.Media.warningOrange.image.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = NearIOSWalletUIKitAsset.Color.green.color
        imageView.contentMode = .center
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 8
        
        
        label.text = "FREE nickname is a gift from HERE Wallet team"
        label.font = NearIOSWalletUIKitFontFamily.Manrope.bold.font(size: 14)
        label.textColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        return stack
    }()
    
    
    private(set) lazy var textField: UITextField = {
        let inset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8)
        let textfiled: UITextField = InsetedUITextfield(inset: inset)
        textfiled.translatesAutoresizingMaskIntoConstraints = false
        textfiled.placeholder = "Nickname"
        textfiled.font = NearIOSWalletUIKitFontFamily.Manrope.medium.font(size: 16)
        textfiled.textColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        
        textfiled.backgroundColor = NearIOSWalletUIKitAsset.Color.elevation1.color
        
        textfiled.layer.cornerRadius = 16
        textfiled.layer.borderWidth = 1
        textfiled.layer.borderColor = NearIOSWalletUIKitAsset.Color.blackPrimary.color.cgColor
        
        textfiled.keyboardType = .asciiCapable
        textfiled.autocorrectionType = .no
        textfiled.autocapitalizationType = .none
        
        return textfiled
    }()
    
    private var errorLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NearIOSWalletUIKitFontFamily.Manrope.medium.font(size: 14)
        label.textColor = NearIOSWalletUIKitAsset.Color.red.color
        return label
    }()
    
    
    private lazy var buttonStack : UIStackView = {
        let views = [createButton(type: .skip), createButton(type: .continue)]
        let stack = UIStackView(arrangedSubviews: views)
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    public func updateErrorLabel(_ text: String) {
        UIView.transition(
            with: errorLabel,
            duration: 0.25,
            options: [.transitionFlipFromTop]
        ) { [weak self] in
            self?.errorLabel.text = text
        }
    }
    
    public func showLoader(_ isShown: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.loader.alpha = isShown ? 1 : 0
        }
    }
    
    override func didMoveToWindow() {
        guard !alreadyMoved else { return }
        backgroundColor = NearIOSWalletUIKitAsset.Color.elevation0.color
        addSubview(nicknameLabel)
        addSubview(freeLabel)
        addSubview(priceLabel)
        addSubview(overlayLine)
        addSubview(descriptionStack)
        addSubview(bgView)
        addSubview(textField)
        addSubview(buttonStack)
        addSubview(errorLabel)
        addSubview(loader)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate(
            [
                nicknameLabel.topAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.topAnchor,
                    constant: 24
                ),
                nicknameLabel.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: 16
                ),
                nicknameLabel.heightAnchor.constraint(equalToConstant: 40)
            ]
        )
        
        NSLayoutConstraint.activate(
            [
                freeLabel.topAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.topAnchor,
                    constant: 24
                ),
                freeLabel.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -16
                ),
                freeLabel.heightAnchor.constraint(equalToConstant: 40)
            ]
        )
        
        NSLayoutConstraint.activate(
            [
                priceLabel.topAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.topAnchor,
                    constant: 38
                ),
                priceLabel.trailingAnchor.constraint(
                    equalTo: freeLabel.leadingAnchor,
                    constant: -8
                ),
                priceLabel.heightAnchor.constraint(equalToConstant: 20)
            ]
        )
        
        NSLayoutConstraint.activate(
            [
                overlayLine.centerXAnchor.constraint(equalTo: priceLabel.centerXAnchor),
                overlayLine.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
                overlayLine.widthAnchor.constraint(
                    equalTo: priceLabel.widthAnchor,
                    constant: 6
                ),
                overlayLine.heightAnchor.constraint(equalToConstant: 1)
            ]
        )
        
        NSLayoutConstraint.activate(
            [
                descriptionStack.topAnchor.constraint(
                    equalTo: nicknameLabel.bottomAnchor,
                    constant: 8
                ),
                descriptionStack.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: 16
                ),
                descriptionStack.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -16
                )
            ]
        )
        
        NSLayoutConstraint.activate(
            [
                textField.topAnchor.constraint(
                    equalTo: descriptionStack.bottomAnchor,
                    constant: 43
                ),
                textField.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: 16
                ),
                textField.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -16
                ),
                textField.heightAnchor.constraint(equalToConstant: 56),
                errorLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 12),
                errorLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor)
            ]
        )
        
        bottomConstraint = buttonStack.bottomAnchor.constraint(
            equalTo: bottomAnchor,
            constant: -24
        )
        
        NSLayoutConstraint.activate(
            [
                bottomConstraint,
                buttonStack.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: 16
                ),
                buttonStack.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -16
                ),
                buttonStack.heightAnchor.constraint(equalToConstant: 56)
            ]
        )
        
        NSLayoutConstraint.activate(
            [
                bgView.topAnchor.constraint(equalTo: textField.topAnchor),
                bgView.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
                bgView.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
                bgView.trailingAnchor.constraint(equalTo: textField.trailingAnchor)
            ]
        )
        NSLayoutConstraint.activate(
            [
                loader.centerXAnchor.constraint(equalTo: centerXAnchor),
                loader.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardNotification(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardNotification(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        alreadyMoved = true
    }
    
    @objc
    private func keyboardNotification(
        _ notification: NSNotification
    ) {
        animateWithKeyboard(notification: notification) { [weak self] keyboardFrame in
            switch notification.name {
            case UIResponder.keyboardWillHideNotification:
                self?.bottomConstraint.constant = -24
                self?.bgView.transform = .identity
            case UIResponder.keyboardWillShowNotification:
                self?.bottomConstraint.constant = -keyboardFrame.height - 24
                self?.bgView.transform = .init(translationX: 4, y: 4)
            default: break
            }
        }
    }
    
    private func createButton(type: Button) -> UIButton {
        
        let black = NearIOSWalletUIKitAsset.Color.blackPrimary.color
        let blackDisabled = NearIOSWalletUIKitAsset.Color.blackDisabled.color
        let blackSecondary = NearIOSWalletUIKitAsset.Color.blackSecondary.color
        
        let button: UIButton
        
        let action = UIAction { [weak self] _ in
            self?.buttonSubject.send(type)
            self?.textField.resignFirstResponder()
        }
        
        switch type {
        case .skip:
            button = PressedWalletButton(buttonType: .bordered(black, 2), action: action)
            button.setTitle("skip", for: .normal)
        case .continue:
            button = PressedWalletButton(
                buttonType: .filled((black, blackDisabled), (.white, blackSecondary)) ,
                action: action
            )
            button.setTitle("continue", for: .normal)
            button.isEnabled = false
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerCurve = .circular
        button.layer.cornerRadius = 24
        button.titleLabel?.font = NearIOSWalletUIKitFontFamily.Manrope.bold.font(size: 16)
        return button
    }
}

