import UIKit

enum UssdDialer {

    /// Replaces every declared `{placeholder}` with the value entered by the user.
    static func dialString(for code: UssdCode, values: [String: String]) -> String {
        code.variables.reduce(code.code) { partial, variable in
            partial.replacingOccurrences(
                of: "{\(variable.key)}",
                with: (values[variable.key] ?? "").trimmingCharacters(in: .whitespaces)
            )
        }
    }

    /// Opens the Phone app with the code. `#` must be percent-encoded or the
    /// URL is rejected, so only digits, `*` and `+` stay literal.
    static func dial(_ dialString: String) {
        var allowed = CharacterSet.decimalDigits
        allowed.insert(charactersIn: "*+")
        guard
            let encoded = dialString.addingPercentEncoding(withAllowedCharacters: allowed),
            let url = URL(string: "tel://\(encoded)"),
            UIApplication.shared.canOpenURL(url)
        else { return }
        UIApplication.shared.open(url)
    }
}
