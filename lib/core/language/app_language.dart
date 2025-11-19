enum AppLanguage {
  english,
  sesotho,
  // Add more languages here in the future
}

extension LanguageExtension on AppLanguage {
  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return "English";
      case AppLanguage.sesotho:
        return "Sesotho";
    }
  }
}
