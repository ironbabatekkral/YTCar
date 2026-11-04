import WebKit

/// Loads the bundled network rules (compiled once, cached by WebKit) and the
/// page-world script that strips YouTube ad data and skips what slips through.
final class AdBlocker {
    static let shared = AdBlocker()

    private static let ruleListID = "ytcar.adrules.v1"
    private var ruleList: WKContentRuleList?
    private var pending: [(WKContentRuleList?) -> Void] = []
    private var compiling = false

    let userScript: WKUserScript? = {
        guard
            let url = Bundle.main.url(forResource: "AdBlock", withExtension: "js"),
            let source = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()

    /// Calls `completion` on the main thread with the compiled list (nil if it failed).
    func withRuleList(_ completion: @escaping (WKContentRuleList?) -> Void) {
        if let ruleList {
            completion(ruleList)
            return
        }
        pending.append(completion)
        guard !compiling else { return }
        compiling = true

        guard
            let url = Bundle.main.url(forResource: "AdRules", withExtension: "json"),
            let json = try? String(contentsOf: url, encoding: .utf8)
        else {
            finish(nil)
            return
        }
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: Self.ruleListID,
            encodedContentRuleList: json
        ) { [weak self] list, error in
            if let error { NSLog("YTCar: rule compile failed: \(error)") }
            self?.finish(list)
        }
    }

    private func finish(_ list: WKContentRuleList?) {
        ruleList = list
        compiling = false
        let callbacks = pending
        pending = []
        callbacks.forEach { $0(list) }
    }
}
