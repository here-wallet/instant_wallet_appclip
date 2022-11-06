import UIKit
import NearIOSWalletUIKit

final public class NicknameGiftViewController: NiblessViewController, UITextFieldDelegate {
    
    private let viewModel: NicknameViewModel
    private let subscriptions: CancelBag = .init()
    
    private var nicknameView: NicknameGiftView?
    private let analytics: AnalyticsAuth?

    public init(viewModel: NicknameViewModel, analytics: AnalyticsAuth?) {
        self.viewModel = viewModel
        self.analytics = analytics
        super.init()
    }
    
    public override func loadView() {
        nicknameView = NicknameGiftView(frame: .zero)
        view = nicknameView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        nicknameView?.textField.delegate = self
        nicknameView?.buttonPublisher
            .sink { [weak viewModel, analytics] event in
                switch event {
                case .continue:
                    analytics?.nickanemGiftCreate()
                    viewModel?.continuePressed()
                case .skip:
                    analytics?.nicknameGiftSkip()
                    viewModel?.skipPressed()
                }
            }
            .store(in: subscriptions)

        
        viewModel.$isContinueActive
            .receive(on: DispatchQueue.main)
            .assign(to: \.continueButton.isEnabled, on: nicknameView!)
            .store(in: subscriptions)
        
        viewModel.$showLoader
            .receive(on: DispatchQueue.main)
            .sink { [weak nicknameView] in
                nicknameView?.showLoader($0)
            }
            .store(in: subscriptions)
        
        viewModel.$suggestionText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.nicknameView?.updateErrorLabel($0)
            }
            .store(in: subscriptions)
        
        nicknameView?.textfieldPublisher
            .compactMap { $0 }
            .map { $0.lowercased() }
            .compactMap { [weak self] in
                self?.addNearEnding(substring: $0)
            }
            .assign(to: \.rawTextfield, on: viewModel)
            .store(in: subscriptions)
        
        viewModel.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.analytics?.nicknameGiftFailure(error: $0.message)
                self?.present(errorMessage: $0)
            }
            .store(in: subscriptions)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nicknameView?.textField.becomeFirstResponder()
        analytics?.nicknameGiftOpen()
    }
    
    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard
            let currentText = textField.text,
            let stringRange = Range(range, in: currentText)
        else {
            return false
        }
        let updatedText = currentText
            .replacingCharacters(in: stringRange, with: string)
            .replacingOccurrences(of: AppInfo.shared.nearDomain, with: "")
        guard !updatedText.isEmpty else {
            textField.text = ""
            viewModel.rawTextfield = ""
            return true
        }
        guard
            updatedText.count <= 64
        else {
            if updatedText.count < (textField.text?.count ?? 0) - 5 {
                textField.text = updatedText
            }
            return false
        }
        return true
    }
    
    func addNearEnding(substring: String) -> String {
        let query = substring.replacingOccurrences(of: AppInfo.shared.nearDomain, with: "")
        let result = self.putColourFormattedTextInTextField(
            autocompleteResult: AppInfo.shared.nearDomain,
            userQuery: query
        )
    
        self.moveCaretToEndOfUserQueryPosition(userQuery: query)
        return result
    }
    
    func putColourFormattedTextInTextField(autocompleteResult: String, userQuery : String) -> String {
        let colouredString: NSMutableAttributedString = .init(string: userQuery + autocompleteResult)
        colouredString.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: NearIOSWalletUIKitAsset.Color.blackDisabled.color,
            range: NSRange(location: userQuery.count, length:autocompleteResult.count)
        )
        
        nicknameView?.textField.attributedText = colouredString
        
        return nicknameView?.textField.attributedText?.string ?? ""
    }
    func moveCaretToEndOfUserQueryPosition(userQuery : String) {
        guard let textField = nicknameView?.textField else { return }
        if let newPosition = textField.position(
            from: textField.beginningOfDocument,
            offset: userQuery.count
        ) {
            textField.selectedTextRange = textField.textRange(
                from: newPosition,
                to: newPosition
            )
        }
    }
}
