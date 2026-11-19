import 'package:hive_flutter/hive_flutter.dart';

class SecureStorageService {
  static const String _boxName = 'auth_box';

  Box get _box => Hive.box(_boxName);

  Future<void> _delete(String key) async {
    await _box.delete(key);
  }

  Future<void> clearAuthSession() async {
    for (final key in [
      LocalStorageKeyStrings.accessToken,
      LocalStorageKeyStrings.legacyIsLogin,
      LocalStorageKeyStrings.refreshToken,
      LocalStorageKeyStrings.user,
      LocalStorageKeyStrings.loggedInUserId,
      LocalStorageKeyStrings.publicToken,
      LocalStorageKeyStrings.userRoleId,
      LocalStorageKeyStrings.userRole,
      LocalStorageKeyStrings.userEmail,
      LocalStorageKeyStrings.userPhone,
      LocalStorageKeyStrings.userFirstName,
      LocalStorageKeyStrings.userLastName,
    ]) {
      await _delete(key);
    }
    await setLoggedIn(false);
  }

  Future<void> setLoggedIn(bool value) async {
    await _box.put(LocalStorageKeyStrings.isLoggedIn, value);
  }

  /// Checks if the user is currently logged in.
  static Future<bool> isLoggedIn() async {
    final box = Hive.box(_boxName);
    final storedStatus = box.get(LocalStorageKeyStrings.isLoggedIn);
    if (storedStatus is bool) return storedStatus;
    if (storedStatus != null) {
      return storedStatus.toString().toLowerCase() == 'true';
    }

    final legacyStatus = box.get(LocalStorageKeyStrings.legacyIsLogin);
    final isLoggedIn = legacyStatus?.toString().toLowerCase() == 'true';
    if (isLoggedIn) {
      await box.put(LocalStorageKeyStrings.isLoggedIn, true);
    }
    return isLoggedIn;
  }
}

class LocalStorageKeyStrings {
  const LocalStorageKeyStrings._();

  static const accessToken = 'access_token';
  static const isLoggedIn = 'isLoggedIn';
  static const legacyIsLogin = 'isLogin';
  static const refreshToken = 'refreshToken';
  static const user = 'user';
  static const loggedInUserId = 'loggedInUserId';
  static const publicToken = 'publicToken';
  static const userRoleId = 'userRoleId';
  static const userRole = 'user_role';
  static const userEmail = 'userEmail';
  static const userPhone = 'userPhone';
  static const userFirstName = 'userFirstName';
  static const userLastName = 'userLastName';
  static const newsBookmarks = 'news_bookmarks';
}
