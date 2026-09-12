import Foundation
import Security

/// The API token lives here rather than in UserDefaults, which is a plist any
/// process running as you can read. The Keychain is the one place macOS gives
/// an app for a credential, and it costs about twenty lines to use.
enum Keychain {
    private static let service = "com.szymonels.timetracker"

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }

        return value
    }

    @discardableResult
    static func write(_ value: String, account: String) -> Bool {
        // An empty value means "forget it" - storing a blank secret would leave
        // the app looking configured when it is not.
        guard !value.isEmpty else { return delete(account) }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [kSecValueData as String: Data(value.utf8)]

        let updated = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updated == errSecSuccess { return true }

        return SecItemAdd(query.merging(attributes) { current, _ in current } as CFDictionary, nil)
            == errSecSuccess
    }

    @discardableResult
    static func delete(_ account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
