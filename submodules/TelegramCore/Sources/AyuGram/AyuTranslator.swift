// AyuGram: translation through Google or Yandex instead of Telegram's own translator.
//
// Mirrors ayu/features/translator in AyuGram Desktop. Text only: formatting is not carried over.

import Foundation
import SwiftSignalKit

public final class AyuTranslator {
    public enum Provider: String, CaseIterable {
        case telegram
        case google
        case yandex

        public var title: String {
            switch self {
            case .telegram:
                return "Telegram"
            case .google:
                return "Google"
            case .yandex:
                return "Yandex"
            }
        }
    }

    private static let storageKey = "ayu.translatorProvider"
    private static let yandexId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()

    public static var provider: Provider {
        if let value = UserDefaults.standard.string(forKey: storageKey), let provider = Provider(rawValue: value) {
            return provider
        }
        return .telegram
    }

    public static func setProvider(_ provider: Provider) {
        UserDefaults.standard.set(provider.rawValue, forKey: storageKey)
    }

    /// Next provider in the list, for a settings row that cycles on tap.
    public static func cycleProvider() {
        let all = Provider.allCases
        let index = all.firstIndex(of: provider) ?? 0
        setProvider(all[(index + 1) % all.count])
    }

    private static func decodeHtml(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "<br>", with: "\n")
        result = result.replacingOccurrences(of: "<br/>", with: "\n")
        result = result.replacingOccurrences(of: "<br />", with: "\n")
        let replacements: [(String, String)] = [("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"), ("&nbsp;", " "), ("&amp;", "&")]
        for (from, to) in replacements {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }

    private static func collectStrings(_ value: Any) -> [String] {
        if let string = value as? String {
            return [string]
        }
        if let array = value as? [Any] {
            return array.flatMap { collectStrings($0) }
        }
        if let dict = value as? [String: Any] {
            var result: [String] = []
            if let text = dict["text"] {
                result.append(contentsOf: collectStrings(text))
            }
            if let trans = dict["trans"] {
                result.append(contentsOf: collectStrings(trans))
            }
            return result
        }
        return []
    }

    private static func googleRequest(text: String, toLang: String) -> URLRequest? {
        guard let url = URL(string: "https://translate-pa.googleapis.com/v1/translateHtml") else {
            return nil
        }
        let prepared = text.replacingOccurrences(of: "\n", with: "<br>")
        let root: [Any] = [[[prepared], "auto", toLang], "wt_lib"]
        guard let body = try? JSONSerialization.data(withJSONObject: root, options: []) else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 15.0
        request.setValue("application/json+protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        // The same public key AyuGram Desktop ships with.
        request.setValue("AIzaSyATBXajvzQLTDHEQbcpq0Ihe0vWDHmO520", forHTTPHeaderField: "X-Goog-Api-Key")
        return request
    }

    private static func yandexRequest(text: String, toLang: String) -> URLRequest? {
        guard var components = URLComponents(string: "https://translate.yandex.net/api/v1/tr.json/translate") else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "srv", value: "android"), URLQueryItem(name: "id", value: "\(yandexId)-0-0")]
        guard let url = components.url else {
            return nil
        }
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let encodedLang = toLang.addingPercentEncoding(withAllowedCharacters: allowed) ?? toLang
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "lang=\(encodedLang)&text=\(encodedText)".data(using: .utf8)
        request.timeoutInterval = 15.0
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("ru.yandex.translate/21.15.4.21402814 (Xiaomi Redmi K20 Pro; Android 11)", forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func parse(provider: Provider, data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        switch provider {
        case .google:
            guard let root = object as? [Any], let first = root.first else {
                return nil
            }
            let combined = collectStrings(first).joined(separator: " ")
            if combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return nil
            }
            return decodeHtml(combined)
        case .yandex:
            guard let dict = object as? [String: Any], let texts = dict["text"] as? [String], !texts.isEmpty else {
                return nil
            }
            return texts.joined(separator: " ")
        case .telegram:
            return nil
        }
    }

    /// Translates plain text with the given provider. Completes with nil when the request or the answer fails.
    public static func translate(provider: Provider, text: String, toLang: String) -> Signal<String?, NoError> {
        return Signal { subscriber in
            let request: URLRequest?
            switch provider {
            case .google:
                request = googleRequest(text: text, toLang: toLang)
            case .yandex:
                request = yandexRequest(text: text, toLang: toLang)
            case .telegram:
                request = nil
            }
            guard let request = request, !text.isEmpty else {
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
            let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                var result: String?
                if let data = data, error == nil {
                    result = parse(provider: provider, data: data)
                }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                AyuGramSettings.debugLog("translate provider=\(provider.rawValue) to=\(toLang) status=\(status) ok=\(result != nil)")
                subscriber.putNext(result)
                subscriber.putCompletion()
            })
            task.resume()
            return ActionDisposable {
                task.cancel()
            }
        }
    }
}
