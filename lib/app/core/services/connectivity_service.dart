import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// خدمة مراقبة حالة الاتصال بالإنترنت
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream لمراقبة التغييرات في الاتصال
  late final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Stream عام للاستماع
  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  /// هل متصل حالياً؟
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// بدء المراقبة
  Future<void> init() async {
    // فحص أولي
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // الاستماع للتغييرات
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  /// تحديث الحالة
  void _updateStatus(List<ConnectivityResult> results) {
    final connected = results.any(
      (r) => r != ConnectivityResult.none,
    );

    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionController.add(connected);
    }
  }

  /// إيقاف المراقبة
  void dispose() {
    _connectionController.close();
  }
}
