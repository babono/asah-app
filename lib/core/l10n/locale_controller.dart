import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/local_store.dart';

/// The interface language (PRD F8). Stored on the device; defaults to the
/// profile's locale, then Bahasa Indonesia.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'pref:locale';

  @override
  Locale? build() {
    final code = ref.watch(localStoreProvider).getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> set(String languageCode) async {
    await ref.read(localStoreProvider).setString(_key, languageCode);
    state = Locale(languageCode);
  }

  /// Use the profile's language unless the person already picked one here.
  void adoptProfileDefault(String languageCode) {
    if (state == null) state = Locale(languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

const supportedLanguageCodes = ['id', 'en'];
