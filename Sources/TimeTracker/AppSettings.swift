import Foundation
import Observation

/// Where the instance is and how to prove who you are. The address is an
/// ordinary preference; the token is a secret, so the two are stored in
/// different places and only meet here.
@MainActor
@Observable
final class AppSettings {
    private enum Key {
        static let address = "serverAddress"
        static let token = "api-token"
    }

    var address: String {
        didSet { UserDefaults.standard.set(address, forKey: Key.address) }
    }

    private(set) var token = ""

    /// False until the token has been fetched. Without it the app would spend
    /// its first moments looking unconfigured to itself and would report as
    /// much to the panel.
    private(set) var isLoaded = false

    var isConfigured: Bool {
        !address.trimmingCharacters(in: .whitespaces).isEmpty
            && !token.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init() {
        address = UserDefaults.standard.string(forKey: Key.address) ?? ""
    }

    /// Fetch the token off the main thread.
    ///
    /// Not in `init`, and never on the main actor: a Keychain read can stop
    /// dead waiting for the "allow access" panel, and one done on the launch
    /// path takes the whole app down with it - no menu bar item, no window,
    /// nothing to click. That is not hypothetical; it is what this app did
    /// until the read moved here.
    func load() async {
        token = await Task.detached { Keychain.read(Key.token) }.value ?? ""
        isLoaded = true
    }

    func update(address newAddress: String, token newToken: String) async {
        address = newAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmed = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        await Task.detached { _ = Keychain.write(trimmed, account: Key.token) }.value
        token = trimmed
    }

    func makeClient() -> Result<APIClient, APIError> {
        APIClient.make(address: address, token: token)
    }
}
