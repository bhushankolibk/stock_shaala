package com.bhushan.stockshaala

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

private const val NATIVE_AD_FACTORY_ID = "listTileNative"

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            NATIVE_AD_FACTORY_ID,
            ListTileNativeAdFactory(layoutInflater)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, NATIVE_AD_FACTORY_ID)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
