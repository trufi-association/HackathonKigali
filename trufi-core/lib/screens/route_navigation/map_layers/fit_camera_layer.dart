import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';

/// Shows viewport rect & fit-point markers when debugFlag is ON.
/// Always supports fit-to-bounds logic regardless of debugFlag.
class FitCameraLayer extends TrufiLayer {
  static const String layerId = 'fit-camera-layer';

  /// Tile size (MapLibre modern = 512).
  final double tileSize;

  /// Extra UI padding (logical px). Added on top of safe inset.
  EdgeInsets insetPx;

  /// Safe-area padding (from MediaQuery.viewPadding).
  EdgeInsets _safeInset = EdgeInsets.zero;

  /// Corner dots (only when debugFlag = true).
  bool showCornerDots;

  /// Visual debug switch: lines/markers render only if true.
  bool debugFlag;

  double _dpr = 1.0; // current devicePixelRatio
  Size _viewportLogical = Size.zero;

  /// Points used for fit; their markers are re-rendered when debugFlag = true.
  List<latlng.LatLng> _fitPoints = const [];

  late final VoidCallback _cameraListener;

  FitCameraLayer(
    super.controller, {
    this.tileSize = 512,
    this.insetPx = const EdgeInsets.all(50),
    this.showCornerDots = true,
    this.debugFlag = true,
  }) : super(id: layerId, layerLevel: 9) {
    _cameraListener = _computeAndRender;
    controller.cameraPositionNotifier.addListener(_cameraListener);
    _computeAndRender();
  }

  @override
  void dispose() {
    controller.cameraPositionNotifier.removeListener(_cameraListener);
    super.dispose();
  }

  /// Toggle visual debug at runtime.
  void setDebug(bool value) {
    debugFlag = value;
    _computeAndRender();
  }

  /// Update viewport logical size and DPR.
  /// Optionally provide safeInset (device padding) and uiInset (extra UI padding).
  void updateViewport(
    Size logicalSize,
    double dpr, {
    EdgeInsets? safeInset,
    EdgeInsets? uiInset,
  }) {
    if (logicalSize.width <= 0 || logicalSize.height <= 0 || dpr <= 0) return;
    _viewportLogical = logicalSize;
    _dpr = dpr;

    if (safeInset != null) _safeInset = safeInset;
    if (uiInset != null) insetPx = uiInset;

    controller.setViewportSize(logicalSize * dpr); // CSS px for MapLibre
    _computeAndRender();
  }

  /// Update only UI padding.
  void updateInset(EdgeInsets inset) {
    insetPx = inset;
    _computeAndRender();
  }

  /// Update only safe-area padding.
  void updateSafeInset(EdgeInsets safe) {
    _safeInset = safe;
    _computeAndRender();
  }

  /// Toggle corner dots (only used when debugFlag = true).
  void setShowCornerDots(bool value) {
    showCornerDots = value;
    _computeAndRender();
  }

  /// Clear fit points (and markers if debugging).
  void clearFitPoints() {
    _fitPoints = const [];
    _computeAndRender();
  }

  // ---------- Web Mercator helpers ----------
  static const _maxLat = 85.05112878;

  double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);
  double _lngToMercX(double lngDeg) => (lngDeg + 180.0) / 360.0;

  double _latToMercY(double latDeg) {
    final lat = _clamp(latDeg, -_maxLat, _maxLat);
    final phi = lat * math.pi / 180.0;
    final s = math.tan(phi) + 1 / math.cos(phi);
    return (1 - (math.log(s) / math.pi)) / 2;
  }

  double _mercXToLng(double x) => x * 360.0 - 180.0;

  double _mercYToLat(double y) {
    final n = math.pi - 2.0 * math.pi * y;
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  // ---------- UI helpers ----------
  Widget _zoomBadge(double z) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.75),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(blurRadius: 4, offset: Offset(0, 1), color: Colors.black26),
      ],
    ),
    child: Text(
      'z: ${z.toStringAsFixed(2)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _dot(Color c) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: c,
      shape: BoxShape.circle,
      boxShadow: const [
        BoxShadow(blurRadius: 4, offset: Offset(0, 1), color: Colors.black26),
      ],
    ),
  );

  Widget _fitDot() => _dot(Colors.pinkAccent);

  // ---------- Main render ----------
  void _computeAndRender() {
    final cam = controller.cameraPositionNotifier.value;
    if (_viewportLogical == Size.zero) {
      // Nothing rendered if viewport size is unknown.
      setLines(const []);
      setMarkers(const []);
      return;
    }

    // Combine safe-area padding + custom UI padding.
    final combinedInset = EdgeInsets.only(
      top: _safeInset.top + insetPx.top,
      right: _safeInset.right + insetPx.right,
      bottom: _safeInset.bottom + insetPx.bottom,
      left: _safeInset.left + insetPx.left,
    );

    final center = cam.target;
    final zoom = cam.zoom;
    final theta = cam.bearing * math.pi / 180.0;
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);

    // 1) Effective viewport in CSS px (minus combined padding).
    final Wcss = math.max(
      1.0,
      (_viewportLogical.width - combinedInset.left - combinedInset.right) *
          _dpr,
    );
    final Hcss = math.max(
      1.0,
      (_viewportLogical.height - combinedInset.top - combinedInset.bottom) *
          _dpr,
    );

    // 2) Center in Mercator (raw).
    final cx0 = _lngToMercX(center.longitude);
    final cy0 = _latToMercY(center.latitude);

    // 3) World size in CSS px at zoom.
    final worldPx = tileSize * math.pow(2.0, zoom);
    final mercPerCssPx = 1.0 / worldPx;

    // 4) Shift center for asymmetric padding (screen axes).
    final shiftMercXLocal =
        ((combinedInset.left - combinedInset.right) * 0.5 * _dpr) *
        mercPerCssPx;
    final shiftMercYLocal =
        ((combinedInset.top - combinedInset.bottom) * 0.5 * _dpr) *
        mercPerCssPx;

    // Rotate shift by bearing (clockwise on screen).
    final shiftMercX = shiftMercXLocal * cosT - shiftMercYLocal * sinT;
    final shiftMercY = shiftMercXLocal * sinT + shiftMercYLocal * cosT;

    // Corrected center.
    final cx = cx0 + shiftMercX;
    final cy = cy0 + shiftMercY;

    // 5) Half extents (with combined padding applied).
    final halfW = (Wcss / 2.0) * mercPerCssPx;
    final halfH = (Hcss / 2.0) * mercPerCssPx;

    // 6) Local corners (before rotation) around corrected center.
    final cornersLocal = <Offset>[
      Offset(-halfW, -halfH),
      Offset(halfW, -halfH),
      Offset(halfW, halfH),
      Offset(-halfW, halfH),
    ];

    latlng.LatLng toLatLng(Offset d) {
      final rx = d.dx * cosT - d.dy * sinT;
      final ry = d.dx * sinT + d.dy * cosT;
      final x = cx + rx;
      final y = cy + ry;
      return latlng.LatLng(_mercYToLat(y), _mercXToLng(x));
    }

    final tl = toLatLng(cornersLocal[0]);
    final tr = toLatLng(cornersLocal[1]);
    final br = toLatLng(cornersLocal[2]);
    final bl = toLatLng(cornersLocal[3]);

    // 7) Closed polyline for the viewport rect (with combined padding).
    final rect = <latlng.LatLng>[bl, tl, tr, br, bl];

    if (debugFlag) {
      final lines = <TrufiLine>[
        TrufiLine(
          id: '$id:viewport-rect',
          position: rect,
          color: Colors.cyan.withOpacity(0.9),
          lineWidth: 3,
          layerLevel: layerLevel,
        ),
      ];

      final markers = <TrufiMarker>[
        // Zoom badge at camera center
        TrufiMarker(
          id: '$id:center-zoom',
          position: center,
          widget: _zoomBadge(zoom),
          layerLevel: layerLevel,
          size: const Size(52, 28),
        ),

        // Corner dots (optional)
        if (showCornerDots) ...[
          TrufiMarker(
            id: '$id:tl',
            position: tl,
            widget: _dot(Colors.amber),
            layerLevel: layerLevel,
            size: const Size(10, 10),
          ),
          TrufiMarker(
            id: '$id:tr',
            position: tr,
            widget: _dot(Colors.amber),
            layerLevel: layerLevel,
            size: const Size(10, 10),
          ),
          TrufiMarker(
            id: '$id:br',
            position: br,
            widget: _dot(Colors.amber),
            layerLevel: layerLevel,
            size: const Size(10, 10),
          ),
          TrufiMarker(
            id: '$id:bl',
            position: bl,
            widget: _dot(Colors.amber),
            layerLevel: layerLevel,
            size: const Size(10, 10),
          ),
        ],

        // Fit points (only visible in debug mode)
        for (int i = 0; i < _fitPoints.length; i++)
          TrufiMarker(
            id: '$id:fit:$i',
            position: _fitPoints[i],
            widget: _fitDot(),
            layerLevel: layerLevel,
            size: const Size(10, 10),
          ),
      ];

      setLines(lines);
      setMarkers(markers);
    } else {
      // Hide visuals when debugFlag is OFF.
      setLines(const []);
      setMarkers(const []);
    }
  }

  // ---------- Fit bounds + point markers ----------
  void fitBoundsOnCamera(
    List<latlng.LatLng> points, {
    double minZoom = 2.0,
    double maxZoom = 20.0,
  }) {
    if (points.isEmpty || _viewportLogical == Size.zero) {
      _fitPoints = const [];
      _computeAndRender();
      return;
    }

    // Store points so markers can be drawn when debugFlag = true.
    _fitPoints = List<latlng.LatLng>.from(points);

    double norm01(double v) {
      v = v % 1.0;
      if (v < 0) v += 1.0;
      return v;
    }

    // 1) Convert to Mercator.
    final xs = <double>[];
    final ys = <double>[];
    for (final p in points) {
      xs.add(_lngToMercX(p.longitude));
      ys.add(_latToMercY(p.latitude));
    }

    // 2) Handle antimeridian crossing for X bounds.
    double xMin = xs.reduce(math.min);
    double xMax = xs.reduce(math.max);
    double spanX = xMax - xMin;

    double cx;
    double dx;
    if (spanX <= 0.5) {
      dx = math.max(spanX, 1e-12);
      cx = (xMin + xMax) / 2.0;
    } else {
      double xMin2 = double.infinity;
      double xMax2 = -double.infinity;
      for (final x in xs) {
        final xx = x < 0.5 ? x + 1.0 : x;
        if (xx < xMin2) xMin2 = xx;
        if (xx > xMax2) xMax2 = xx;
      }
      dx = math.max(xMax2 - xMin2, 1e-12);
      cx = norm01((xMin2 + xMax2) / 2.0);
    }

    // 3) Y bounds.
    final yMin = ys.reduce(math.min);
    final yMax = ys.reduce(math.max);
    final dy = math.max(yMax - yMin, 1e-12);
    final cy = (yMin + yMax) / 2.0;

    // 4) Effective viewport with combined padding + rotation projection.
    final cam = controller.cameraPositionNotifier.value;
    final theta = cam.bearing * math.pi / 180.0;
    final absCos = math.cos(theta).abs();
    final absSin = math.sin(theta).abs();

    final combinedInset = EdgeInsets.only(
      top: _safeInset.top + insetPx.top,
      right: _safeInset.right + insetPx.right,
      bottom: _safeInset.bottom + insetPx.bottom,
      left: _safeInset.left + insetPx.left,
    );

    final Wcss = math.max(
      1.0,
      (_viewportLogical.width - combinedInset.left - combinedInset.right) *
          _dpr,
    );
    final Hcss = math.max(
      1.0,
      (_viewportLogical.height - combinedInset.top - combinedInset.bottom) *
          _dpr,
    );

    // Projected viewport that guarantees bbox fits at current bearing.
    final Wproj = Wcss * absCos + Hcss * absSin;
    final Hproj = Wcss * absSin + Hcss * absCos;

    // 5) Required zoom.
    final zX = math.log(Wproj / (tileSize * dx)) / math.ln2;
    final zY = math.log(Hproj / (tileSize * dy)) / math.ln2;
    final zoom = _zoomClamp(
      (zX.isFinite && zY.isFinite) ? math.min(zX, zY) : cam.zoom,
      minZoom,
      maxZoom,
    );

    // 6) Center correction for asymmetric padding.
    final worldPx = tileSize * math.pow(2.0, zoom);
    final mercPerCssPx = 1.0 / worldPx;

    final shiftXLocal =
        ((combinedInset.left - combinedInset.right) * 0.5 * _dpr) *
        mercPerCssPx;
    final shiftYLocal =
        ((combinedInset.top - combinedInset.bottom) * 0.5 * _dpr) *
        mercPerCssPx;

    final shiftX =
        shiftXLocal * math.cos(theta) - shiftYLocal * math.sin(theta);
    final shiftY =
        shiftXLocal * math.sin(theta) + shiftYLocal * math.cos(theta);

    final cxc = norm01(cx - shiftX);
    final cyc = (cy - shiftY).clamp(0.0, 1.0);

    final target = latlng.LatLng(_mercYToLat(cyc), _mercXToLng(cxc));

    // 7) Apply camera (keep bearing) and render.
    controller.updateCamera(target: target, zoom: zoom);
    _computeAndRender();
  }

  double _zoomClamp(double z, double minZ, double maxZ) {
    if (z < minZ) return minZ;
    if (z > maxZ) return maxZ;
    return z;
  }
}
