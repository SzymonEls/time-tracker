import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(TimerStore.self) private var store

    @State private var address = ""
    @State private var token = ""
    @State private var check: CheckResult?
    @State private var isChecking = false

    private enum CheckResult: Equatable {
        case success(String)
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Server")
                    .font(.system(size: 12, weight: .semibold))
                TextField("https://productivity.example.com", text: $address)
                    .textFieldStyle(.roundedBorder)
                Text("The address you open the productivity app at.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("API token")
                    .font(.system(size: 12, weight: .semibold))
                SecureField("Paste the token", text: $token)
                    .textFieldStyle(.roundedBorder)
                Text("Account page → API token → Copy.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("Test connection") { Task { await test() } }
                    .disabled(isChecking || address.isEmpty || token.isEmpty)

                if isChecking {
                    ProgressView().controlSize(.small)
                }

                if let check {
                    switch check {
                    case .success(let username):
                        Label("Signed in as \(username)", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    case .failure(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }

            Divider()

            HStack {
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 400)
        .task {
            // The panel can be opened before the Keychain has answered, so the
            // fields are filled from the settings only once they are loaded.
            if !settings.isLoaded { await settings.load() }
            address = settings.address
            token = settings.token
        }
    }

    private func test() async {
        isChecking = true
        defer { isChecking = false }

        switch APIClient.make(address: address, token: token) {
        case .failure(let error):
            check = .failure(error.errorDescription ?? "Check the address and token.")
        case .success(let client):
            do {
                check = .success(try await client.verify())
            } catch let error as APIError {
                check = .failure(error.errorDescription ?? "Could not reach the server.")
            } catch {
                check = .failure(error.localizedDescription)
            }
        }
    }

    private func save() {
        Task {
            await settings.update(address: address, token: token)
            await store.refresh()
        }
    }
}
