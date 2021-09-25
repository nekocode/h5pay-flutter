import Flutter
import UIKit
import WebKit

public class SwiftH5payPlugin: NSObject, FlutterPlugin {
    private var targetSchemes = [String]()
    private var httpHeaders = [String:String]()
    private var webView: WKWebView? = nil
    private var result: FlutterResult? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "h5pay", binaryMessenger: registrar.messenger())
        let instance = SwiftH5payPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "launchRedirectUrl":
            launchRedirectUrl(call, result: result)
            break
        case "launchUrl":
            launchUrl(call, result: result)
            break
        case "canLaunch":
            canLaunch(call, result: result)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    private func launchRedirectUrl(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let arguments = call.arguments as? [String: Any],
            let urlString = arguments["url"] as? String,
            let url = URL(string: urlString)
            else {
                result(false)
                return
        }
        if let targetSchemes = arguments["targetSchemes"] as? [String] {
            self.targetSchemes = targetSchemes
        } else {
            self.targetSchemes = [String]()
        }
        if let httpHeaders = arguments["httpHeaders"] as? [String:String] {
            self.httpHeaders = httpHeaders
        } else {
            self.httpHeaders = [String:String]()
        }
        
        // Try to launch url directly
        if (Utils.hasScheme(url, targetSchemes)) {
            result(Utils.launchUrl(url))
            return
        }
        
        initWebView()
        validateWebView()
        
        self.result = result
        var request = URLRequest.init(url: url)
        for (key, value) in self.httpHeaders {
            request.setValue(key, forHTTPHeaderField: value)
        }
        webView!.load(request)
    }
    
    private func launchUrl(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let arguments = call.arguments as? [String: Any],
            let urlString = arguments["url"] as? String,
            let url = URL(string: urlString)
            else {
                result(false)
                return
        }
        result(Utils.launchUrl(url))
    }
    
    private func canLaunch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let arguments = call.arguments as? [String: Any],
            let urlString = arguments["url"] as? String,
            let url = URL(string: urlString)
            else {
                result(false)
                return
        }
        result(Utils.canLaunch(url))
    }
    
    private func initWebView() {
        if (webView != nil) {
            return
        }
        
        let config: WKWebViewConfiguration = WKWebViewConfiguration()
        if #available(iOS 9.0, *) {
            config.allowsPictureInPictureMediaPlayback = false
            config.requiresUserActionForMediaPlayback = true
        }
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = .all
        }
        config.allowsInlineMediaPlayback = true
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        config.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isHidden = true
        webView.navigationDelegate = self
        self.webView = webView
        
        validateWebView()
    }
    
    private func validateWebView() {
        if webView != nil && webView?.superview == nil {
            UIApplication.shared.keyWindow?.addSubview(webView!)
        }
    }
}

extension SwiftH5payPlugin: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(decidePolicyForRequest(navigationAction.request))
    }
    
    private func decidePolicyForRequest(_ request: URLRequest) -> WKNavigationActionPolicy {
        if let url = request.url {
            if (Utils.hasScheme(url, targetSchemes)) {
                result?(Utils.launchUrl(url))
                return .cancel
            }
        }
        return .allow
    }
}

class Utils {
    public static func launchUrl(_ url: URL) -> Bool {
        if !canLaunch(url) {
            return false
        } else {
            let success = UIApplication.shared.openURL(url)
            return success
        }
    }
    
    public static func canLaunch(_ url: URL) -> Bool {
        return UIApplication.shared.canOpenURL(url)
    }
    
    public static func hasScheme(_ url: URL, _ targetSchemes: [String]) -> Bool {
        let urlString = url.absoluteString
        for scheme in targetSchemes {
            if !urlString.hasPrefix(scheme + ":") {
                continue
            }
            return true
        }
        return false
    }
}
