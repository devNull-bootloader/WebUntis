import Foundation
import SwiftUI

@MainActor
class UntisViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var lessons: [Lesson] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate = Date()

    private var client: WebUntisClient?

    func login(school: String, baseURL: String, username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            var newClient = WebUntisClient(school: school, baseURL: baseURL, identity: "UntisSwiftApp")
            try await newClient.login(username: username, password: password)
            client = newClient
            isLoggedIn = true
            await loadTimetable(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadTimetable(for date: Date) async {
        guard let client else { return }
        isLoading = true
        errorMessage = nil
        do {
            var fetchedLessons = try await client.getTimetableFor(date: date)
            fetchedLessons.sort { $0.startTime < $1.startTime }
            lessons = fetchedLessons
            selectedDate = date
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() async {
        do {
            try await client?.logout()
        } catch {}
        client = nil
        isLoggedIn = false
        lessons = []
        errorMessage = nil
    }
}
