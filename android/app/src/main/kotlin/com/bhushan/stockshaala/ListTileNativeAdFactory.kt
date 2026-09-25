package com.bhushan.stockshaala

import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

/**
 * Inflates list_tile_native_ad.xml and binds a loaded [NativeAd] to it.
 * Registered under the "listTileNative" factory id (see MainActivity),
 * matched by factoryId in NativeAd.load on the Dart side.
 */
class ListTileNativeAdFactory(private val layoutInflater: LayoutInflater) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.list_tile_native_ad, null
        ) as NativeAdView

        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        val body = adView.findViewById<TextView>(R.id.ad_body)
        val icon = adView.findViewById<ImageView>(R.id.ad_icon)
        val media = adView.findViewById<MediaView>(R.id.ad_media)
        val advertiser = adView.findViewById<TextView>(R.id.ad_advertiser)
        val stars = adView.findViewById<RatingBar>(R.id.ad_stars)
        val cta = adView.findViewById<Button>(R.id.ad_cta)

        headline.text = nativeAd.headline
        adView.headlineView = headline

        if (nativeAd.body.isNullOrEmpty()) {
            body.visibility = android.view.View.GONE
        } else {
            body.text = nativeAd.body
            body.visibility = android.view.View.VISIBLE
        }
        adView.bodyView = body

        val icAsset = nativeAd.icon
        if (icAsset != null) {
            icon.setImageDrawable(icAsset.drawable)
            icon.visibility = android.view.View.VISIBLE
        } else {
            icon.visibility = android.view.View.GONE
        }
        adView.iconView = icon

        // Only show the MediaView (and give it to the SDK to render into)
        // when this ad actually has media content — otherwise it sits at
        // its default "gone" size, which the SDK read as too small to
        // play the video it was trying to place there.
        if (nativeAd.mediaContent != null) {
            media.visibility = android.view.View.VISIBLE
            adView.mediaView = media
        } else {
            media.visibility = android.view.View.GONE
        }

        if (nativeAd.advertiser.isNullOrEmpty()) {
            advertiser.visibility = android.view.View.GONE
        } else {
            advertiser.text = nativeAd.advertiser
            advertiser.visibility = android.view.View.VISIBLE
        }
        adView.advertiserView = advertiser

        if (nativeAd.starRating == null) {
            stars.visibility = android.view.View.GONE
        } else {
            stars.rating = nativeAd.starRating!!.toFloat()
            stars.visibility = android.view.View.VISIBLE
        }
        adView.starRatingView = stars

        if (nativeAd.callToAction.isNullOrEmpty()) {
            cta.visibility = android.view.View.GONE
        } else {
            cta.text = nativeAd.callToAction
            cta.visibility = android.view.View.VISIBLE
        }
        adView.callToActionView = cta

        adView.setNativeAd(nativeAd)
        return adView
    }
}
