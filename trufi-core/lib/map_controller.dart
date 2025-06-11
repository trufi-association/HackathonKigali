import 'dart:async';
import 'package:latlong2/latlong.dart';

class TrufiCameraPosition {
  final LatLng position;
  final double zoom;
  final double bearing;

  TrufiCameraPosition({
    required this.position,
    required this.zoom,
    this.bearing = 0,
  });
}

class TrufiMapController {
  late final TrufiCameraPosition _initialCamera;
  TrufiCameraPosition _currentCamera;
  final _cameraPositionController =
      StreamController<TrufiCameraPosition>.broadcast();

  TrufiMapController({required TrufiCameraPosition initialCamera})
    : _initialCamera = initialCamera,
      _currentCamera = initialCamera;

  Stream<TrufiCameraPosition> get cameraPositionStream =>
      _cameraPositionController.stream;

  TrufiCameraPosition get initialCamera => _initialCamera;
  TrufiCameraPosition get currentCamera => _currentCamera;

  bool moveCamera(TrufiCameraPosition newCamera) {
    if (newCamera.position == _currentCamera.position &&
        newCamera.zoom == _currentCamera.zoom &&
        newCamera.bearing == _currentCamera.bearing) {
      return false;
    }

    _currentCamera = TrufiCameraPosition(
      position: newCamera.position,
      zoom: newCamera.zoom,
      bearing: newCamera.bearing % 360,
    );
    _emitCameraPosition(_currentCamera);
    return true;
  }

  bool rotate(double degree) {
    final newBearing = (degree % 360);
    if (newBearing == _currentCamera.bearing) {
      return false;
    }

    _currentCamera = TrufiCameraPosition(
      position: _currentCamera.position,
      zoom: _currentCamera.zoom,
      bearing: newBearing,
    );
    _emitCameraPosition(_currentCamera);
    return true;
  }

  bool moveAndRotate(TrufiCameraPosition newCamera, double degree) {
    final rotated = rotate(degree);
    final moved = moveCamera(newCamera);
    return rotated || moved;
  }

  void _emitCameraPosition(TrufiCameraPosition cameraPosition) {
    if (!_cameraPositionController.isClosed) {
      _cameraPositionController.add(cameraPosition);
    }
  }

  void dispose() {
    _cameraPositionController.close();
  }
}
