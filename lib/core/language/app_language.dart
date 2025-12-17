enum AppLanguage {
  english,
  sesotho,
  // Add more languages here in the future

  ;

  // List of supported languages for UI iteration
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage.english,
    AppLanguage.sesotho,
  ];
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

  // Provide a name alias used by UI
  String get name => displayName;

  // Machine-readable code for persisting or sending to services
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'english';
      case AppLanguage.sesotho:
        return 'sesotho';
    }
  }

  // Optionally create from code
  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'sesotho':
        return AppLanguage.sesotho;
      case 'english':
      default:
        return AppLanguage.english;
    }
  }
}
