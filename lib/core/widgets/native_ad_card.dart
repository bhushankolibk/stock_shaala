import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../di/injection.dart';
import '../services/ad_service.dart';

/// Drop-in native ad card for scrollable feeds (news list, stock list).
/// Loads its own [NativeAd], renders nothing while loading/failed so it
/// never leaves a gap, and disposes the ad on unmount.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard>
    with AutomaticKeepAliveClientMixin<NativeAdCard> {
  NativeAd? _ad;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    sl<AdService>().createNativeAd(
      onLoaded: (ad) {
        if (mounted) {
          setState(() => _ad = ad);
        } else {
          ad.dispose();
        }
      },
      onFailed: () {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (ad == null || _failed) return const SizedBox.shrink();
    // Card bg/border/radius are already drawn by list_tile_native_ad.xml
    // (native_ad_background) so the ad blends into the surrounding feed.
    // No margin here — callers wrap this in whatever spacing matches their
    // own item style.
    //
    // AdWidget wraps a platform view, which needs a concrete, bounded size
    // up front — it can't report its own intrinsic size back to Flutter's
    // layout like a normal widget. A ConstrainedBox with only minHeight (no
    // max) leaves it unbounded inside a lazy ListView/SliverList, which
    // throws "given an infinite size during layout". A fixed SizedBox
    // avoids that; the height below comfortably fits list_tile_native_ad.xml
    // (badge + optional 120dp MediaView + icon/headline/body row +
    // advertiser/stars + CTA button) so video creative isn't clipped.
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: AdWidget(ad: ad),
    );
  }
}
