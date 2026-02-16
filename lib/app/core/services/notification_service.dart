import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/supabase_client.dart';

/// معالج الرسائل في الخلفية (يجب أن يكون top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // يمكن معالجة الإشعارات في الخلفية هنا
}

/// خدمة الإشعارات - Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// FCM Token الحالي
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Stream للإشعارات الواردة (في الـ Foreground)
  final StreamController<RemoteMessage> _onMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  // ─── التهيئة ───

  /// إعداد FCM
  Future<void> init() async {
    // طلب الإذن
    await _requestPermission();

    // الحصول على Token
    _fcmToken = await _messaging.getToken();

    // الاستماع لتحديث Token
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _updateTokenInDatabase(newToken);
    });

    // الاستماع للإشعارات في الـ Foreground
    FirebaseMessaging.onMessage.listen((message) {
      _onMessageController.add(message);
    });

    // الاستماع لضغط على إشعار (التطبيق مغلق أو في الخلفية)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // فحص إذا التطبيق فُتح من إشعار
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ─── الإذن ───

  /// طلب إذن الإشعارات
  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  // ─── Token ───

  /// تحديث Token في قاعدة البيانات
  Future<void> _updateTokenInDatabase(String token) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('users')
            .update({'fcm_token': token})
            .eq('auth_id', user.id);
      }
    } catch (_) {
      // نتجاهل - سيُحدّث عند التسجيل
    }
  }

  /// حفظ Token للمستخدم الحالي
  Future<void> saveTokenForCurrentUser() async {
    if (_fcmToken != null) {
      await _updateTokenInDatabase(_fcmToken!);
    }
  }

  // ─── معالجة الضغط على الإشعار ───

  /// معالجة الضغط على الإشعار
  void _handleNotificationTap(RemoteMessage message) {
    // TODO: التنقل حسب نوع الإشعار
    // final type = message.data['type'];
    // مثال: attendance_confirmed, badge_earned, note_received
  }

  // ─── الاشتراك في Topics ───

  /// الاشتراك في topic مسجد معين
  Future<void> subscribeToMosque(String mosqueId) async {
    await _messaging.subscribeToTopic('mosque_$mosqueId');
  }

  /// إلغاء الاشتراك من topic مسجد
  Future<void> unsubscribeFromMosque(String mosqueId) async {
    await _messaging.unsubscribeFromTopic('mosque_$mosqueId');
  }

  // ─── تنظيف ───

  void dispose() {
    _onMessageController.close();
  }
}
