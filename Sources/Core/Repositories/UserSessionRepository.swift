import Foundation

public protocol UserSessionRepository {
    func readUserSession() async throws -> UserSession?
    func signUp(mnemonic: [String], isNew: Bool) async throws -> UserSession
    func signOut() async throws
}

