import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: UntisViewModel

    @State private var school = ""
    @State private var host = ""
    @State private var username = ""
    @State private var password = ""

    private var isFormValid: Bool {
        !school.trimmingCharacters(in: .whitespaces).isEmpty &&
        !host.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 56))
                                .foregroundStyle(.tint)
                            Text("Untis")
                                .font(.largeTitle.bold())
                            Text("WebUntis Timetable")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section("School") {
                    TextField("School identifier (e.g. myschool)", text: $school)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("WebUntis host (e.g. mese.webuntis.com)", text: $host)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Account") {
                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            await viewModel.login(
                                school: school.trimmingCharacters(in: .whitespaces),
                                baseURL: host.trimmingCharacters(in: .whitespaces),
                                username: username.trimmingCharacters(in: .whitespaces),
                                password: password
                            )
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Log In")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
