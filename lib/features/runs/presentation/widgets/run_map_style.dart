import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

/// Loads the vector map style once per app run and shares it between all
/// map pages. OpenFreeMap is free for commercial use and needs no key.
class RunMapStyle {
  RunMapStyle._();

  static const _styleUrl = 'https://tiles.openfreemap.org/styles/fiord';

  /// Background of the style, shown while tiles are still loading.
  static const background = Color(0xFF45516E);

  static Future<vt.Style?>? _style;

  /// Null when the style could not be loaded (offline on first start). The
  /// route is still drawn then, only without the map underneath.
  static Future<vt.Style?> load() => _style ??= _read();

  static Future<vt.Style?> _read() async {
    try {
      return await vt.StyleReader(uri: _styleUrl).read();
    } on Exception catch (error) {
      debugPrint('RunMapStyle: could not load $_styleUrl: $error');
      _style = null; // retry when the next map opens
      return null;
    }
  }
}
