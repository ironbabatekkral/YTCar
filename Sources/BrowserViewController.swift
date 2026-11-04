import UIKit
import WebKit

/// YouTube in a WKWebView with the ad blocker attached. Used by both the phone
/// window and the car window. Each window owns its web view; they share the
/// default website data store, so signing in on the phone signs in the car
/// after a reload.
final class BrowserViewController: UIViewController, WKUIDelegate {
    private static let home = URL(string: "https://m.youtube.com")!

    private let webView: WKWebView
    private let toolbar = UIToolbar()
    private var observers: [NSKeyValueObservation] = []

    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        // Google refuses sign-in in web views that identify as embedded; a
        // Safari-style user agent lets the normal sign-in page load.
        config.applicationNameForUserAgent = "Version/18.0 Mobile/15E148 Safari/604.1"
        if let script = AdBlocker.shared.userScript {
            config.userContentController.addUserScript(script)
        }
        webView = WKWebView(frame: .zero, configuration: config)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .black
        webView.isOpaque = false

        let back = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            primaryAction: UIAction { [weak self] _ in self?.webView.goBack() })
        let forward = UIBarButtonItem(
            image: UIImage(systemName: "chevron.forward"),
            primaryAction: UIAction { [weak self] _ in self?.webView.goForward() })
        let reload = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            primaryAction: UIAction { [weak self] _ in self?.webView.reload() })
        let home = UIBarButtonItem(
            image: UIImage(systemName: "house"),
            primaryAction: UIAction { [weak self] _ in
                self?.webView.load(URLRequest(url: Self.home))
            })
        let airplay = UIBarButtonItem(
            image: UIImage(systemName: "airplayvideo"),
            primaryAction: UIAction { [weak self] _ in self?.showPlaybackTargetPicker() })
        let space = UIBarButtonItem.flexibleSpace()
        toolbar.items = [back, space, forward, space, reload, space, home, space, airplay]
        toolbar.barStyle = .black

        observers = [
            webView.observe(\.canGoBack, options: [.initial, .new]) { wv, _ in
                back.isEnabled = wv.canGoBack
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { wv, _ in
                forward.isEnabled = wv.canGoForward
            },
        ]

        webView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addSubview(toolbar)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // Rules must be attached before the first load or the first page escapes them.
        AdBlocker.shared.withRuleList { [weak self] list in
            guard let self else { return }
            if let list { self.webView.configuration.userContentController.add(list) }
            self.webView.load(URLRequest(url: Self.home))
        }
    }

    // MARK: - AirPlay (experimental car route)

    private func showPlaybackTargetPicker() {
        let js = """
        (() => {
          const v = document.querySelector('video');
          if (v && typeof v.webkitShowPlaybackTargetPicker === 'function') {
            v.webkitShowPlaybackTargetPicker();
            return true;
          }
          return false;
        })()
        """
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard (result as? Bool) != true else { return }
            let alert = UIAlertController(
                title: "AirPlay açılamadı",
                message: "Önce bir video açın. Sayfadaki oynatıcı AirPlay'i desteklemiyor olabilir.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            self?.present(alert, animated: true)
        }
    }

    // MARK: - WKUIDelegate

    /// target=_blank and window.open load in the same view instead of vanishing.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
