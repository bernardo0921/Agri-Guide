import 'package:flutter/material.dart';
import '../language/app_language.dart';

class AppNotifiers {
  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier(AppLanguage.english);
}
