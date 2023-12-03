package cn.nekocode.h5pay

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.view.View
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class H5payPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private var targetSchemes: Iterable<String> = emptyList()
    private var httpHeaders: Map<String, String> = emptyMap()
    private var webView: WebView? = null
    private var result: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        channel = MethodChannel(binding.binaryMessenger, "h5pay")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "launchRedirectUrl" -> {
                launchRedirectUrl(call, result)
            }
            "launchUrl" -> {
                launchUrl(call, result)
            }
            "canLaunch" -> {
                canLaunch(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun launchRedirectUrl(call: MethodCall, result: Result) {
        val arguments = call.arguments as? HashMap<*, *>
        targetSchemes = (arguments?.get("targetSchemes") as? Iterable<*>)
            ?.filterIsInstance<String>()
            ?: emptyList()
        @Suppress("UNCHECKED_CAST")
        httpHeaders = (arguments?.get("httpHeaders") as? Map<String, String>) ?: emptyMap()

        // Try to launch url directly
        val url = (arguments?.get("url") as? String)
        if (url == null) {
            result.success(false)
            return
        }
        if (Utils.hasScheme(url, targetSchemes)) {
            result.success(Utils.launchUrl(binding.applicationContext, url))
            return
        }

        initWebView()

        this.result = result
        webView!!.run {
            stopLoading()
            loadUrl(url, httpHeaders)
        }
    }

    private fun launchUrl(call: MethodCall, result: Result) {
        val arguments = call.arguments as? HashMap<*, *>
        val url = arguments?.get("url") as? String
        result.success(Utils.launchUrl(binding.applicationContext, url))
    }

    private fun canLaunch(call: MethodCall, result: Result) {
        val arguments = call.arguments as? HashMap<*, *>
        val url = arguments?.get("url") as? String
        if (url == null) {
            result.success(false)
            return
        }
        result.success(Utils.canLaunch(binding.applicationContext, url))
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun initWebView() {
        if (webView != null) {
            return
        }

        val context = binding.applicationContext
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            if (0 != (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE)) {
                WebView.setWebContentsDebuggingEnabled(true)
            }
        }

        val webView = WebView(context)
        webView.visibility = View.GONE
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.settings.allowFileAccessFromFileURLs = true
        webView.settings.allowUniversalAccessFromFileURLs = true
        webView.settings.loadsImagesAutomatically = false
        webView.settings.blockNetworkImage = false
        webView.webViewClient = Client()
        this.webView = webView
    }

    inner class Client : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
            return shouldOverrideUrlLoading(url)
        }

        @TargetApi(Build.VERSION_CODES.LOLLIPOP)
        override fun shouldOverrideUrlLoading(
            view: WebView?,
            request: WebResourceRequest?
        ): Boolean {
            val url = request?.url?.toString()
            return shouldOverrideUrlLoading(url)
        }

        private fun shouldOverrideUrlLoading(url: String?): Boolean {
            if (Utils.hasScheme(url, targetSchemes)) {
                result?.success(Utils.launchUrl(binding.applicationContext, url))
                return true
            }
            return false
        }
    }
}

object Utils {
    private const val FALLBACK_COMPONENT_NAME =
        "{com.android.fallback/com.android.fallback.Fallback}"

    fun launchUrl(context: Context, url: String?): Boolean {
        return if (!canLaunch(context, url)) {
            false
        } else {
            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    fun canLaunch(context: Context, url: String?): Boolean {
        url ?: return false
        val launchIntent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse(url)
        }
        val componentName = launchIntent.resolveActivity(context.packageManager)

        return componentName != null &&
                FALLBACK_COMPONENT_NAME != componentName.toShortString()
    }

    fun hasScheme(url: String?, targetSchemes: Iterable<String>): Boolean {
        url ?: return false
        for (scheme in targetSchemes) {
            if (!url.startsWith("$scheme:")) {
                continue
            }
            return true
        }
        return false
    }
}
