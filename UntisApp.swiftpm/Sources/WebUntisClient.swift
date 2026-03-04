import Foundation

// WebUntisClient mirrors the authentication and timetable fetch logic
// from the JavaScript WebUntis library using the JSON-RPC API over HTTPS.
struct WebUntisClient {
    let school: String
    let baseURL: String
    let identity: String

    private(set) var sessionId: String?
    private(set) var personId: Int?
    private(set) var personType: Int?

    // The schoolname cookie value is "_" + Base64(school), matching the JS library's btoa() logic.
    private var schoolBase64: String {
        "_" + Data(school.utf8).base64EncodedString()
    }

    private var sessionCookies: String? {
        guard let sessionId else { return nil }
        return "JSESSIONID=\(sessionId); schoolname=\(schoolBase64)"
    }

    private func jsonRpcURL() throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = baseURL
        components.path = "/WebUntis/jsonrpc.do"
        components.queryItems = [URLQueryItem(name: "school", value: school)]
        guard let url = components.url else {
            throw WebUntisError.invalidResponse
        }
        return url
    }

    private func makeRequest(body: [String: Any], cookies: String? = nil) throws -> URLRequest {
        var request = URLRequest(url: try jsonRpcURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        if let cookies {
            request.setValue(cookies, forHTTPHeaderField: "Cookie")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // Authenticate with username and password.
    // Matches Base.login() in the JS library.
    mutating func login(username: String, password: String) async throws {
        let body: [String: Any] = [
            "id": identity,
            "method": "authenticate",
            "params": [
                "user": username,
                "password": password,
                "client": identity
            ],
            "jsonrpc": "2.0"
        ]
        let request = try makeRequest(body: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WebUntisError.invalidResponse
        }
        if let error = json["error"] as? [String: Any] {
            throw WebUntisError.loginFailed(error["message"] as? String)
        }
        guard
            let result = json["result"] as? [String: Any],
            let sid = result["sessionId"] as? String
        else {
            throw WebUntisError.loginFailed(nil)
        }
        sessionId = sid
        personId = result["personId"] as? Int
        personType = result["personType"] as? Int
    }

    // Fetch the timetable for the logged-in user for a given date.
    // Matches Base.getOwnTimetableFor() in the JS library.
    func getTimetableFor(date: Date) async throws -> [Lesson] {
        guard let personId, let personType else {
            throw WebUntisError.notAuthenticated
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        guard let dateInt = Int(dateFormatter.string(from: date)) else {
            throw WebUntisError.invalidResponse
        }
        let body: [String: Any] = [
            "id": identity,
            "method": "getTimetable",
            "params": [
                "options": [
                    "id": Int(Date().timeIntervalSince1970 * 1000),
                    "element": [
                        "id": personId,
                        "type": personType
                    ],
                    "startDate": dateInt,
                    "endDate": dateInt,
                    "showLsText": true,
                    "showStudentgroup": true,
                    "showLsNumber": true,
                    "showSubstText": true,
                    "showInfo": true,
                    "showBooking": true,
                    "klasseFields": ["id", "name", "longname"],
                    "roomFields": ["id", "name", "longname"],
                    "subjectFields": ["id", "name", "longname"],
                    "teacherFields": ["id", "name", "longname"]
                ]
            ],
            "jsonrpc": "2.0"
        ]
        let request = try makeRequest(body: body, cookies: sessionCookies)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WebUntisError.invalidResponse
        }
        if let error = json["error"] as? [String: Any] {
            throw WebUntisError.serverError((error["message"] as? String) ?? "Unknown error")
        }
        guard let result = json["result"] as? [[String: Any]] else {
            throw WebUntisError.invalidResponse
        }
        return result.compactMap(Lesson.init(raw:))
    }

    // End the current session. Matches Base.logout() in the JS library.
    func logout() async throws {
        let body: [String: Any] = [
            "id": identity,
            "method": "logout",
            "params": [:] as [String: Any],
            "jsonrpc": "2.0"
        ]
        let request = try makeRequest(body: body, cookies: sessionCookies)
        _ = try await URLSession.shared.data(for: request)
    }
}
