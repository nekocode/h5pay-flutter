package cn.nekocode.h5pay

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.view.View
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class H5payPlugin(private val registrar: Registrar) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "h5pay")
            channel.setMethodCallHandler(H5payPlugin(registrar))
        }
    }

    private var targetSchemes: Iterable<String> = emptyList()
    private var webView: WebView? = null
    private var result: Result? = null

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

        // Try to launch url directly
        val url = arguments?.get("url") as? String
        if (Utils.hasScheme(url, targetSchemes)) {
            result.success(Utils.launchUrl(registrar.activity(), url))
            return
        }

        initWebView()

        this.result = result
        webView!!.run {
            stopLoading()
            loadUrl(url)
        }
    }

    private fun launchUrl(call: MethodCall, result: Result) {
        val arguments = call.arguments as? HashMap<*, *>
        val url = arguments?.get("url") as? String
        result.success(Utils.launchUrl(registrar.activity(), url))
    }

    private fun canLaunch(call: MethodCall, result: Result) {
        val arguments = call.arguments as? HashMap<*, *>
        val url = arguments?.get("url") as? String
        if (url == null) {
            result.success(false)
            return
        }
        result.success(Utils.canLaunch(registrar.activity(), url))
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun initWebView() {
        if (webView != null) {
            return
        }

        val activity = registrar.activity()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            if (0 != (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE)) {
                WebView.setWebContentsDebuggingEnabled(true)
            }
        }

        val webView = WebView(activity)
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
                result?.success(Utils.launchUrl(registrar.activity(), url))
                return true
            }
            return false
        }
    }
}

object Utils {
    private const val FALLBACK_COMPONENT_NAME =
        "{com.android.fallback/com.android.fallback.Fallback}"

    fun launchUrl(activity: Activity, url: String?): Boolean {
        return if (!canLaunch(activity, url)) {
            false
        } else {
            try {
                activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
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
