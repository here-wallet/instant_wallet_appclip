import Foundation
import UIKit

public struct ErrorMessage: Error {

  // MARK: - Properties
  public let id: UUID
  public let title: String
  public let message: String

  // MARK: - Methods
  public init(title: String, message: String) {
    self.id = UUID()
    self.title = title
    self.message = message
  }
}

extension ErrorMessage: Equatable {
    public static func ==(lhs: ErrorMessage, rhs: ErrorMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ErrorMessage {
    public init(error: Error) {
        let title = "Something went wrong"
        let message = error.localizedDescription
        self.init(title: title, message: message)
    }
}

public extension UIViewController {
    // MARK: - Methods
    func present(errorMessage: ErrorMessage, ok: ((UIAlertAction) -> Void)? = nil) {
        let errorAlertController = UIAlertController(title: errorMessage.title,
                                                     message: errorMessage.message,
                                                     preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: ok)
        errorAlertController.addAction(okAction)
        present(errorAlertController, animated: true, completion: nil)
    }
}

extension ErrorMessage {
    public static let featureInProgress: ErrorMessage = .init(
        title: "Feature in progress",
        message: "Feature will be availabe in future release. Stay tuned🚀"
    )
    
    public static let errorTryLater: ErrorMessage = .init(
        title: "Error",
        message: "Please try again later"
    )
}
