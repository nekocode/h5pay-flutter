import Flutter
import UIKit
import WebKit

private class ReturnCode {
    public static let success = 1
    public static let fail = 0
    public static let failCantJump = -1
}

public class SwiftH5payPlugin: NSObject, FlutterPlugin {
    private var paymentSchemes = [String]()
    private var webView: WKWebView? = nil
    private var result: FlutterResult? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "h5pay", binaryMessenger: registrar.messenger())
        let instance = SwiftH5payPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "launch" {
            launch(call, result: result)
        }
    }
    
    private func launch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let arguments = call.arguments as? [String: Any],
            let urlString = arguments["url"] as? String,
            let url = URL(string: urlString)
            else {
                result(ReturnCode.fail)
                return
        }
        if let paymentSchemes = arguments["paymentSchemes"] as? [String] {
            self.paymentSchemes = paymentSchemes
        }
        
        // Try run url directly
        if (launchApp(url, result: result)) {
            return
        }
        
        initWebView()
        validateWebView()
        
        self.result = result
        webView!.load(URLRequest.init(url: url))
    }
    
    private func launchApp(_ url: URL, result: @escaping FlutterResult) -> Bool {
        for scheme in paymentSchemes {
            if url.absoluteString.hasPrefix(scheme + ":") {
                let app = UIApplication.shared
                if !app.canOpenURL(url) {
                    result(ReturnCode.failCantJump)
                    return false
                    
                } else {
                    let success = app.openURL(url)
                    result(success ? ReturnCode.success : ReturnCode.fail)
                    return success
                }
            }
        }
        return false
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
            if (launchApp(url, result: self.result!)) {
                // Interrupt this request
                return .cancel
            }
        }
        return .allow
    }
}
