import Foundation

enum APIError: LocalizedError, Equatable {
    case notConfigured
    case badURL(String)
    case unauthorized
    case server(String)
    case transport(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Add your server address and token in Settings."
        case .badURL(let value):
            return "\(value) is not a valid address."
        case .unauthorized:
            return "The server rejected the token. Generate a new one on the account page."
        case .server(let message):
            return message
        case .transport(let message):
            return message
        case .decoding(let message):
            return "The server answered with something unexpected. \(message)"
        }
    }
}

/// Talks to the productivity app's `/api/v1`. A value type on purpose: it holds
/// no state of its own, so the store rebuilds one whenever settings change
/// rather than keeping a mutable client in sync with them.
struct APIClient: Sendable {
    let baseURL: URL
    let token: String

    /// Build a client, or fail with the reason the settings are unusable.
    static func make(address: String, token: String) -> Result<APIClient, APIError> {
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty, !token.isEmpty else { return .failure(.notConfigured) }

        // A bare host is the likeliest thing to be typed, so read it as https
        // rather than refusing it.
        let normalized = address.contains("://") ? address : "https://\(address)"
        guard let url = URL(string: normalized), url.host != nil else {
            return .failure(.badURL(address))
        }

        return .success(APIClient(baseURL: url, token: token))
    }

    func today() async throws -> Today {
        try await send(path: "today", method: "GET", body: nil)
    }

    func start(projectID: Int) async throws -> Today {
        try await send(path: "timer/start", method: "POST", body: ["project_id": projectID])
    }

    func stop(description: String?) async throws -> Today {
        var body: [String: Any] = [:]
        if let description, !description.isEmpty { body["description"] = description }
        return try await send(path: "timer/stop", method: "POST", body: body)
    }

    /// Cheap settings check: `/me` touches no timer and no project.
    func verify() async throws -> String {
        struct Me: Decodable { let user: User; struct User: Decodable { let username: String } }
        let me: Me = try await send(path: "me", method: "GET", body: nil)
        return me.user.username
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        body: [String: Any]?
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: "api/v1/\(path)"))
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if status == 401 { throw APIError.unauthorized }
            let message = (try? Self.decoder.decode(APIErrorBody.self, from: data))?.message
            throw APIError.server(message ?? "The server answered \(status).")
        }

        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Flask writes microseconds, which the fractional-seconds formatter
        // handles - but an entry saved on a whole second has no fraction at
        // all, so both formats have to be accepted.
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            for date in [parseWithFraction(text), parseWithoutFraction(text)] {
                if let date { return date }
            }
            throw APIError.decoding("\(text) is not a timestamp this app understands.")
        }
        return decoder
    }()

    // Built per call rather than cached in a static: ISO8601DateFormatter is a
    // class with mutable options, so a shared one is not Sendable, and this
    // runs a handful of times per response - not per row of anything.
    private static func parseWithFraction(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: text)
    }

    private static func parseWithoutFraction(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: text)
    }
}
