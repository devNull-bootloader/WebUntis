# WebUntis API

This is a NodeJS Wrapper for the JSON RPC WebUntis API.

The Documentation is available at [https://webuntis.noim.me/](https://webuntis.noim.me/)

In case you need the Untis API Spec (pdf), you need to email Untis directly and ask. I am (legally) not allowed to publish it.

## Note:

As I have not been a student for a long time, I currently have no access to any Untis services. If you want to share your login details with me for testing purposes, contact me via [Telegram](t.me/TheNoim) or other means ([Homepage](noim.io)).

## Examples

### User/Password Login

```javascript
import { WebUntis } from 'webuntis';

const untis = new WebUntis('school', 'username', 'password', 'xyz.webuntis.com');

await untis.login();
const timetable = await untis.getOwnTimetableForToday();

// profit
```

### QR Code Login

```javascript
import { WebUntisQR } from 'webuntis';
import { URL } from 'url';
import { authenticator as Authenticator } from 'otplib';

// The result of the scanned QR Code
const QRCodeData = 'untis://setschool?url=[...]&school=[...]&user=[...]&key=[...]&schoolNumber=[...]';

const untis = new WebUntisQR(QRCodeData, 'custom-identity', Authenticator, URL);

await untis.login();
const timetable = await untis.getOwnTimetableForToday();

// profit
```

### User/Secret Login

```javascript
import { WebUntisSecretAuth } from 'webuntis';
import { authenticator as Authenticator } from 'otplib';

const secret = 'NL04FGY4FSY5';

const untis = new WebUntisSecretAuth('school', 'username', secret, 'xyz.webuntis.com', 'custom-identity', Authenticator);

await untis.login();
const timetable = await untis.getOwnTimetableForToday();

// profit
```

### Anonymous Login

Only if your school supports public access.

```javascript
import { WebUntisAnonymousAuth, WebUntisElementType } from 'webuntis';

const untis = new WebUntisAnonymousAuth('school', 'xyz.webuntis.com');

await untis.login();
const classes = await untis.getClasses();
const timetable = await untis.getTimetableForToday(classes[0].id, WebUntisElementType.CLASS);

// profit
```

### Installation

This package is compatible with CJS and ESM. *Note:* This package primary target is nodejs. It may also work with runtimes like react-native, but it will probably not work in the browser.

```bash
yarn add webuntis
# Or
npm i webuntis --save
# Or
pnpm i webuntis
```

### ESM note:

If you use the esm version of this package, you need to provide `Authenticator` and `URL` if necessary. For more information, look at the `User/Secret Login` or `QR Code Login` example. This is not needed for `username/password` or `anonymous` login. 

### Swift / Swift Playgrounds

This package is written in JavaScript/TypeScript and cannot be used directly in Swift or Swift Playgrounds. However, since the WebUntis API is a JSON-RPC API over HTTPS, you can call it natively from Swift using `URLSession`.

The following example shows how to log in with username and password and fetch your own timetable for today:

```swift
import Foundation

struct WebUntisClient {
    let school: String
    let baseURL: String
    let identity: String

    private(set) var sessionId: String?
    private(set) var personId: Int?
    private(set) var personType: Int?

    private var schoolBase64: String {
        "_" + Data(school.utf8).base64EncodedString()
    }

    private var sessionCookies: String? {
        guard let sessionId else { return nil }
        return "JSESSIONID=\(sessionId); schoolname=\(schoolBase64)"
    }

    private func jsonRpcURL() -> URL {
        URL(string: "https://\(baseURL)/WebUntis/jsonrpc.do?school=\(school)")!
    }

    private func makeRequest(body: [String: Any], cookies: String? = nil) throws -> URLRequest {
        var request = URLRequest(url: jsonRpcURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        if let cookies {
            request.setValue(cookies, forHTTPHeaderField: "Cookie")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

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
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = json["result"] as? [String: Any],
            let sid = result["sessionId"] as? String
        else { throw URLError(.badServerResponse) }
        sessionId = sid
        personId = result["personId"] as? Int
        personType = result["personType"] as? Int
    }

    func getTimetableForToday() async throws -> [[String: Any]] {
        guard let personId, let personType else {
            throw URLError(.userAuthenticationRequired)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let today = Int(dateFormatter.string(from: Date()))!
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
                    "startDate": today,
                    "endDate": today,
                    "showLsText": true,
                    "showStudentgroup": true,
                    "showLsNumber": true,
                    "showSubstText": true,
                    "showInfo": true,
                    "showBooking": true
                ]
            ],
            "jsonrpc": "2.0"
        ]
        let request = try makeRequest(body: body, cookies: sessionCookies)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = json["result"] as? [[String: Any]]
        else { throw URLError(.badServerResponse) }
        return result
    }

    func logout() async throws {
        let body: [String: Any] = [
            "id": identity,
            "method": "logout",
            "params": [:],
            "jsonrpc": "2.0"
        ]
        let request = try makeRequest(body: body, cookies: sessionCookies)
        _ = try await URLSession.shared.data(for: request)
    }
}

// Usage
var client = WebUntisClient(school: "myschool", baseURL: "xyz.webuntis.com", identity: "MyApp")
try await client.login(username: "username", password: "password")
let timetable = try await client.getTimetableForToday()
print(timetable)
try await client.logout()
```

**Note:** The WebUntis server uses session cookies (`JSESSIONID` and `schoolname`) for authentication after login. The `schoolname` cookie value is `_` followed by the Base64-encoded school identifier. Make sure your app has the **Outgoing Connections** capability enabled when running in Swift Playgrounds or as a sandboxed app.

### Notice

I am not affiliated with Untis GmbH. Use this at your own risk.
