import Foundation

enum UpdateChecker {
    static let repo = "polunzh/KeepGoing"

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// Compare two semantic version strings. Returns true if `remote` is newer than `local`.
    static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }

    /// Strip "v" prefix from tag name.
    static func versionFromTag(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    /// Check GitHub for latest release. Returns (version, url) if newer version available.
    static func checkForUpdate() async -> (version: String, url: URL)? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard
                let tagName = json?["tag_name"] as? String,
                let htmlURL = json?["html_url"] as? String,
                let releaseURL = URL(string: htmlURL)
            else { return nil }

            let remoteVersion = versionFromTag(tagName)
            if isNewer(remoteVersion, than: currentVersion) {
                return (remoteVersion, releaseURL)
            }
        } catch {}

        return nil
    }
}
