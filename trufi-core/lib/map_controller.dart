import 'dart:async';
import 'package:latlong2/latlong.dart';

/// Represents the camera position with coordinates, zoom, and bearing (rotation)
class TrufiCameraPosition {
  final LatLng position;
  final double zoom;
  final double bearing;

  TrufiCameraPosition({
    required this.position,
    required this.zoom,
    required this.bearing,
  });
}

/// Controller to programmatically interact with the map
class TrufiMapController {
  late final TrufiCameraPosition _initialCamera;
  TrufiCameraPosition _currentCamera;

  /// Stream controller for broadcasting camera position updates
  final _cameraPositionController = StreamController<TrufiCameraPosition>.broadcast();

  /// Constructor to initialize the controller with the initial camera position
  TrufiMapController({required TrufiCameraPosition initialCamera})
      : _initialCamera = initialCamera,
        _currentCamera = initialCamera;

  /// Stream of camera position updates
  Stream<TrufiCameraPosition> get cameraPositionStream => _cameraPositionController.stream;

  /// Get the initial camera position
  TrufiCameraPosition get initialCamera => _initialCamera;

  /// Get the current camera position
  TrufiCameraPosition get currentCamera => _currentCamera;

  /// Moves the camera to a new position, returns true if moved
  bool moveCamera(TrufiCameraPosition newCamera) {
    if (newCamera.position == _currentCamera.position &&
        newCamera.zoom == _currentCamera.zoom &&
        newCamera.bearing == _currentCamera.bearing) {
      return false; // No movement required
    }

    _currentCamera = TrufiCameraPosition(
      position: newCamera.position,
      zoom: newCamera.zoom,
      bearing: newCamera.bearing % 360,
    );
    _emitCameraPosition(_currentCamera); // Emit the new camera position
    return true;
  }

  /// Rotates the camera to the specified degree, returns true if rotated
  bool rotate(double degree) {
    final newBearing = (degree % 360);
    if (newBearing == _currentCamera.bearing) {
      return false; // No rotation required
    }

    _currentCamera = TrufiCameraPosition(
      position: _currentCamera.position,
      zoom: _currentCamera.zoom,
      bearing: newBearing,
    );
    _emitCameraPosition(_currentCamera); // Emit the new camera position
    return true;
  }

  /// Moves and rotates the camera, returns true if either action is performed
  bool moveAndRotate(TrufiCameraPosition newCamera, double degree) {
    final rotated = rotate(degree);
    final moved = moveCamera(newCamera);
    return rotated || moved;
  }

  /// Emits the current camera position through the stream
  void _emitCameraPosition(TrufiCameraPosition cameraPosition) {
    if (!_cameraPositionController.isClosed) {
      _cameraPositionController.add(cameraPosition);
    }
  }

  /// Cleans up resources and listeners
  void dispose() {
    _cameraPositionController.close();
  }
}
