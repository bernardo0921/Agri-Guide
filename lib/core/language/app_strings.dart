import '../notifiers/app_notifiers.dart';
import 'app_language.dart';

class AppStrings {
  // Login Screen
  static String get welcomeTitle {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Welcome to AgriGuide";
      case AppLanguage.sesotho:
        return "Rea u amohela ho AgriGuide";
    }
  }

  static String get welcomeSubtitle {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Sign in to continue";
      case AppLanguage.sesotho:
        return "Kena ho tsoela pele";
    }
  }

  static String get username {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Username";
      case AppLanguage.sesotho:
        return "Lebitso la mosebedisi";
    }
  }

  static String get password {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Password";
      case AppLanguage.sesotho:
        return "Phasewete";
    }
  }

  static String get login {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Login";
      case AppLanguage.sesotho:
        return "Kena";
    }
  }

  static String get noAccount {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Don't have an account?";
      case AppLanguage.sesotho:
        return "Ha o na ak'haonte?";
    }
  }

  static String get createAccount {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Create Account";
      case AppLanguage.sesotho:
        return "Etsa Ak'haonte";
    }
  }

  // Role Selection Screen
  static String get joinAgriGuide {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Join AgriGuide";
      case AppLanguage.sesotho:
        return "Ikopanye le AgriGuide";
    }
  }

  static String get chooseRole {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Choose your role to get started";
      case AppLanguage.sesotho:
        return "Khetha karolo ea hau ho qala";
    }
  }

  static String get imAFarmer {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "I'm a Farmer";
      case AppLanguage.sesotho:
        return "Ke Molemisi";
    }
  }

  static String get farmerDescription {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Access AI-powered farming advice, tutorials, and connect with the farming community";
      case AppLanguage.sesotho:
        return "Fumana likeletso tsa temo tse nang le AI, lithupelo le ho hokahana le sechaba sa balemisi";
    }
  }

  static String get imAnExtensionWorker {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "I'm an Extension Worker";
      case AppLanguage.sesotho:
        return "Ke Mosebeletsi oa Tlatsetso";
    }
  }

  static String get extensionWorkerDescription {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Share your expertise by creating educational tutorials and guides for farmers";
      case AppLanguage.sesotho:
        return "Arolelana tsebo ea hau ka ho theha lithupelo le litataiso tsa thuto bakeng sa balemisi";
    }
  }

  static String get backToLogin {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Back to Login";
      case AppLanguage.sesotho:
        return "Khutlela ho Kena";
    }
  }

  // Common Registration Fields
  static String get email {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Email";
      case AppLanguage.sesotho:
        return "Emeile";
    }
  }

  static String get confirmPassword {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Confirm Password";
      case AppLanguage.sesotho:
        return "Netefatsa Phasewete";
    }
  }

  static String get firstName {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "First Name";
      case AppLanguage.sesotho:
        return "Lebitso la Pele";
    }
  }

  static String get lastName {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Last Name";
      case AppLanguage.sesotho:
        return "Lebitso la Morao";
    }
  }

  static String get phoneNumber {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Phone Number";
      case AppLanguage.sesotho:
        return "Nomoro ea Mohala";
    }
  }

  static String get register {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Register";
      case AppLanguage.sesotho:
        return "Ingodise";
    }
  }

  // Farmer Registration
  static String get registerAsFarmer {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Register as Farmer";
      case AppLanguage.sesotho:
        return "Ingodise e le Molemisi";
    }
  }

  static String get createFarmerAccount {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Create Farmer Account";
      case AppLanguage.sesotho:
        return "Etsa Ak'haonte ea Molemisi";
    }
  }

  static String get farmDetails {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Farm Details";
      case AppLanguage.sesotho:
        return "Lintlha tsa Polasi";
    }
  }

  static String get farmName {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Farm Name";
      case AppLanguage.sesotho:
        return "Lebitso la Polasi";
    }
  }

  static String get farmSize {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Farm Size (in acres)";
      case AppLanguage.sesotho:
        return "Boholo ba Polasi (ka lieka)";
    }
  }

  static String get location {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Location (e.g., Town/Village)";
      case AppLanguage.sesotho:
        return "Sebaka (mohlala, Toropo/Motse)";
    }
  }

  static String get region {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Region";
      case AppLanguage.sesotho:
        return "Sebaka";
    }
  }

  static String get cropsGrown {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Crops Grown (comma-separated)";
      case AppLanguage.sesotho:
        return "Lijalo tse Lemileng (arohaneng ka khomo)";
    }
  }

  static String get yearsOfExperience {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Years of Experience";
      case AppLanguage.sesotho:
        return "Lilemo tsa Boiphihlelo";
    }
  }

  static String get farmingMethod {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Farming Method";
      case AppLanguage.sesotho:
        return "Mokhoa oa Temo";
    }
  }

  static String get conventional {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Conventional";
      case AppLanguage.sesotho:
        return "Tlhaho";
    }
  }

  static String get organic {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Organic";
      case AppLanguage.sesotho:
        return "Organic";
    }
  }

  static String get mixed {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Mixed";
      case AppLanguage.sesotho:
        return "Motswako";
    }
  }

  // Extension Worker Registration
  static String get registerAsExtensionWorker {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Register as Extension Worker";
      case AppLanguage.sesotho:
        return "Ingodise e le Mosebeletsi oa Tlatsetso";
    }
  }

  static String get createExtensionWorkerAccount {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Create Extension Worker Account";
      case AppLanguage.sesotho:
        return "Etsa Ak'haonte ea Mosebeletsi oa Tlatsetso";
    }
  }

  static String get accountPendingApproval {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Your account will be reviewed and approved by an administrator";
      case AppLanguage.sesotho:
        return "Ak'haonte ea hau e tla hlahlojoa 'me e amoheloe ke motsamaisi";
    }
  }

  static String get accountInformation {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Account Information";
      case AppLanguage.sesotho:
        return "Tlhahisoleseling ea Ak'haonte";
    }
  }

  static String get personalInformation {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Personal Information";
      case AppLanguage.sesotho:
        return "Tlhahisoleseling ea Botho";
    }
  }

  static String get professionalDetails {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Professional Details";
      case AppLanguage.sesotho:
        return "Lintlha tsa Profeshenale";
    }
  }

  static String get organization {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Organization/Institution";
      case AppLanguage.sesotho:
        return "Mokhatlo/Setheo";
    }
  }

  static String get employeeId {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Employee ID";
      case AppLanguage.sesotho:
        return "Nomoro ea Mosebeletsi";
    }
  }

  static String get specialization {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Specialization (e.g., Crop Science)";
      case AppLanguage.sesotho:
        return "Bokhethoa (mohlala, Saense ea Lijalo)";
    }
  }

  static String get regionsCovered {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Regions Covered (comma-separated)";
      case AppLanguage.sesotho:
        return "Libaka tse Koahetsoeng (arohaneng ka khomo)";
    }
  }

  static String get verificationDocument {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Verification Document";
      case AppLanguage.sesotho:
        return "Tokomane ea Netefatso";
    }
  }

  static String get uploadDocumentDescription {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Upload an official document (ID, certificate, or employment letter)";
      case AppLanguage.sesotho:
        return "Kenya tokomane ea semmuso (ID, setifikeiti, kapa lengolo la mosebetsi)";
    }
  }

  static String get uploadDocument {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Upload Document";
      case AppLanguage.sesotho:
        return "Kenya Tokomane";
    }
  }

  // Validation Messages
  static String get passwordsDoNotMatch {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Passwords do not match.";
      case AppLanguage.sesotho:
        return "Liphasewete ha li lumellane.";
    }
  }

  static String get pleaseEnterValidEmail {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Please enter a valid email";
      case AppLanguage.sesotho:
        return "Ka kopo kenya emeile e nepahetseng";
    }
  }

  static String get fieldRequired {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "This field is required";
      case AppLanguage.sesotho:
        return "Lebala lena le hlokahala";
    }
  }

  static String get pleaseEnterUsername {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Please enter your username";
      case AppLanguage.sesotho:
        return "Ka kopo kenya lebitso la hau la mosebedisi";
    }
  }

  static String get pleaseEnterPassword {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Please enter your password";
      case AppLanguage.sesotho:
        return "Ka kopo kenya phasewete ea hau";
    }
  }

  // Success Messages
  static String get registrationSuccessful {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Registration successful! Your account is pending approval.";
      case AppLanguage.sesotho:
        return "Ngodiso e atlehile! Ak'haonte ea hau e emetse tumello.";
    }
  }

  // Error Messages
  static String get errorPickingFile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Error picking file";
      case AppLanguage.sesotho:
        return "Phoso ho khetha faele";
    }
  }

  // Auth Wrapper
  static String get loading {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Loading...";
      case AppLanguage.sesotho:
        return "E ntse e jara...";
    }
  }

  // Image Viewer Screen
  static String get share {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Share";
      case AppLanguage.sesotho:
        return "Arolelana";
    }
  }

  static String get deletePost {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Delete Post";
      case AppLanguage.sesotho:
        return "Phumola Poso";
    }
  }

  static String get deletePostConfirm {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Are you sure you want to delete this post?";
      case AppLanguage.sesotho:
        return "Na u na le bonnete ba hore u batla ho phumola puso ena?";
    }
  }

  static String get cancel {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Cancel";
      case AppLanguage.sesotho:
        return "Hlakola";
    }
  }

  static String get delete {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Delete";
      case AppLanguage.sesotho:
        return "Phumola";
    }
  }

  static String get postDeletedSuccessfully {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Post deleted successfully";
      case AppLanguage.sesotho:
        return "Poso e phumoliloe ka katleho";
    }
  }

  static String get failedToDeletePost {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Failed to delete post";
      case AppLanguage.sesotho:
        return "Ho hlōlehile ho phumola poso";
    }
  }

  static String get failedToUpdateLike {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Failed to update like";
      case AppLanguage.sesotho:
        return "Ho hlōlehile ho ntlafatsa thabo";
    }
  }

  static String get shareFunctionalityComingSoon {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Share functionality coming soon!";
      case AppLanguage.sesotho:
        return "Ts'ebetso ea ho arolelana e tla tla haufinyane!";
    }
  }

  static String get failedToLoadImage {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Failed to load image";
      case AppLanguage.sesotho:
        return "Ho hlōlehile ho jara setšoantšo";
    }
  }

  // Post Detail Screen
  static String get postDetails {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Post Details";
      case AppLanguage.sesotho:
        return "Lintlha tsa Poso";
    }
  }

  static String get failedToLoadPost {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Failed to load post";
      case AppLanguage.sesotho:
        return "Ho hlōlehile ho jara poso";
    }
  }

  static String get unknownError {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Unknown error";
      case AppLanguage.sesotho:
        return "Phoso e sa tsejoeng";
    }
  }

  static String get retry {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Retry";
      case AppLanguage.sesotho:
        return "Leka hape";
    }
  }

  static String get postNotFound {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Post not found";
      case AppLanguage.sesotho:
        return "Poso ha e fumanehe";
    }
  }

  static String get postMayBeDeleted {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "This post may have been deleted";
      case AppLanguage.sesotho:
        return "Puso ena e kanna ea ba e phumuliloe";
    }
  }

  static String get goBack {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Go Back";
      case AppLanguage.sesotho:
        return "Khutla Morao";
    }
  }

  // Settings Page
  static String get settings {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Settings";
      case AppLanguage.sesotho:
        return "Litlhophiso";
    }
  }

  static String get appearance {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Appearance";
      case AppLanguage.sesotho:
        return "Ponahalo";
    }
  }

  static String get darkMode {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Dark Mode";
      case AppLanguage.sesotho:
        return "Mokhoa oa Lefifi";
    }
  }

  static String get enabled {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Enabled";
      case AppLanguage.sesotho:
        return "E butsoe";
    }
  }

  static String get disabled {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Disabled";
      case AppLanguage.sesotho:
        return "E thibetsoeng";
    }
  }

  static String get darkModeEnabled {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Dark mode enabled";
      case AppLanguage.sesotho:
        return "Mokhoa oa lefifi o butsoe";
    }
  }

  static String get lightModeEnabled {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Light mode enabled";
      case AppLanguage.sesotho:
        return "Mokhoa oa khanya o butsoe";
    }
  }

  static String get notifications {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Notifications";
      case AppLanguage.sesotho:
        return "Litsebiso";
    }
  }

  static String get pushNotifications {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Push Notifications";
      case AppLanguage.sesotho:
        return "Litsebiso tsa Push";
    }
  }

  static String get emailNotifications {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Email Notifications";
      case AppLanguage.sesotho:
        return "Litsebiso tsa Emeile";
    }
  }

  static String get privacySecurity {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Privacy & Security";
      case AppLanguage.sesotho:
        return "Lekunutu le Ts'ireletso";
    }
  }

  static String get privacySettings {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Privacy Settings";
      case AppLanguage.sesotho:
        return "Litlhophiso tsa Lekunutu";
    }
  }

  static String get changePassword {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Change Password";
      case AppLanguage.sesotho:
        return "Fetola Phasewete";
    }
  }

  static String get account {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Account";
      case AppLanguage.sesotho:
        return "Ak'haonte";
    }
  }

  static String get manageProfile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Manage Profile";
      case AppLanguage.sesotho:
        return "Laola Profaele";
    }
  }

  static String get connectedApps {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Connected Apps";
      case AppLanguage.sesotho:
        return "Lisebelisoa tse Hokahaneng";
    }
  }

  static String get support {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Support";
      case AppLanguage.sesotho:
        return "Tšehetso";
    }
  }

  static String get helpFeedback {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Help & Feedback";
      case AppLanguage.sesotho:
        return "Thuso le Maikutlo";
    }
  }

  static String get reportBug {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Report a Bug";
      case AppLanguage.sesotho:
        return "Tlaleha Phoso";
    }
  }

  static String get about {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "About";
      case AppLanguage.sesotho:
        return "Ka";
    }
  }

  static String get termsOfService {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Terms of Service";
      case AppLanguage.sesotho:
        return "Lipehelo tsa Tšebeletso";
    }
  }

  static String get privacyPolicy {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Privacy Policy";
      case AppLanguage.sesotho:
        return "Pholisi ea Lekunutu";
    }
  }

  static String get appVersion {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "App Version";
      case AppLanguage.sesotho:
        return "Mofuta oa Sesebelisoa";
    }
  }

  static String get version {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Version 1.0.0";
      case AppLanguage.sesotho:
        return "Mofuta 1.0.0";
    }
  }

  static String get logout {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Logout";
      case AppLanguage.sesotho:
        return "Tsoa";
    }
  }

  static String get logoutConfirm {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Are you sure you want to logout?";
      case AppLanguage.sesotho:
        return "Na u na le bonnete ba hore u batla ho tsoa?";
    }
  }

  static String get comingSoon {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Coming soon";
      case AppLanguage.sesotho:
        return "E tla tla haufinyane";
    }
  }

  static String comingSoonFor(String feature) {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "$feature is coming soon";
      case AppLanguage.sesotho:
        return "$feature e tla tla haufinyane";
    }
  }

  // Home Screen
  static String get dashboard {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Dashboard";
      case AppLanguage.sesotho:
        return "Letlapa la Taolo";
    }
  }

  static String get aiAdvisory {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "AI Advisory";
      case AppLanguage.sesotho:
        return "Likeletso tsa AI";
    }
  }

  static String get community {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Community";
      case AppLanguage.sesotho:
        return "Sechaba";
    }
  }

  static String get learning {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Learning";
      case AppLanguage.sesotho:
        return "Thuto";
    }
  }

  static String get profile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Profile";
      case AppLanguage.sesotho:
        return "Profaele";
    }
  }

  static String get helpSupport {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Help & Support";
      case AppLanguage.sesotho:
        return "Thuso le TÅ¡ehetso";
    }
  }

  static String get settingsComingSoon {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Settings - Coming soon";
      case AppLanguage.sesotho:
        return "Litlhophiso - E tla tla haufinyane";
    }
  }

  static String get helpSupportComingSoon {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Help & Support - Coming soon";
      case AppLanguage.sesotho:
        return "Thuso le TÅ¡ehetso - E tla tla haufinyane";
    }
  }

  static String get logoutTitle {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Logout";
      case AppLanguage.sesotho:
        return "Tsoa";
    }
  }

  // Profile Page Strings
  static String get myProfile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "My Profile";
      case AppLanguage.sesotho:
        return "Profaele ea Ka";
    }
  }

  static String get accountDetails {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Account Details";
      case AppLanguage.sesotho:
        return "Lintlha tsa Ak'haonte";
    }
  }

  static String get emailAddress {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Email Address";
      case AppLanguage.sesotho:
        return "Aterese ea Emeile";
    }
  }

  static String get farmer {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Farmer";
      case AppLanguage.sesotho:
        return "Molemisi";
    }
  }

  static String get extensionWorker {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Extension Worker";
      case AppLanguage.sesotho:
        return "Mosebeletsi oa Tlatsetso";
    }
  }

  static String get workerDetails {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Worker Details";
      case AppLanguage.sesotho:
        return "Lintlha tsa Mosebeletsi";
    }
  }

  static String get farmingProfile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Farming Profile";
      case AppLanguage.sesotho:
        return "Profaele ea Temo";
    }
  }

  static String get noFarmingProfileAvailable {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "No farming profile information available";
      case AppLanguage.sesotho:
        return "Ha ho na tlhahisoleseling ea profaele ea temo";
    }
  }

  static String get acres {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "acres";
      case AppLanguage.sesotho:
        return "lieka";
    }
  }

  static String get years {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "years";
      case AppLanguage.sesotho:
        return "lilemo";
    }
  }

  static String get editProfile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Edit Profile";
      case AppLanguage.sesotho:
        return "Fetola Profaele";
    }
  }

  static String get failedToLoadProfile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Failed to load profile";
      case AppLanguage.sesotho:
        return "Ho hlōlehile ho jara profaele";
    }
  }

  static String get unknownErrorOccurred {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Unknown error occurred";
      case AppLanguage.sesotho:
        return "Phoso e sa tsejoeng e etsahetse";
    }
  }

  // Edit Profile Page Strings
  static String get personalInformationTitle {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Personal Information";
      case AppLanguage.sesotho:
        return "Tlhahisoleseling ea Botho";
    }
  }

  static String get tapCameraToChangePhoto {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Tap camera icon to change photo";
      case AppLanguage.sesotho:
        return "Tobetsa lethathamo la khemera ho fetola setšoantšo";
    }
  }

  static String get chooseFromGallery {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Choose from Gallery";
      case AppLanguage.sesotho:
        return "Khetha ho tsoa Galereng";
    }
  }

  static String get takePhoto {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Take a Photo";
      case AppLanguage.sesotho:
        return "Nka Setšoantšo";
    }
  }

  static String get removePhoto {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Remove Photo";
      case AppLanguage.sesotho:
        return "Tlosa Setšoantšo";
    }
  }

  static String get saving {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Saving...";
      case AppLanguage.sesotho:
        return "E ntse e boloka...";
    }
  }

  static String get saveChanges {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Save Changes";
      case AppLanguage.sesotho:
        return "Boloka Liphetoho";
    }
  }

  static String get profileUpdatedSuccessfully {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Profile updated successfully!";
      case AppLanguage.sesotho:
        return "Profaele e ntlafalitsoe ka katleho!";
    }
  }

  static String get failedToUpdateProfile {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Failed to update profile";
      case AppLanguage.sesotho:
        return "Ho hlōlehile ho ntlafatsa profaele";
    }
  }

  static String get failedToPickImage {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Failed to pick image";
      case AppLanguage.sesotho:
        return "Ho hlōlehile ho khetha setšoantšo";
    }
  }

  static String get farmSizeAcres {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Farm Size (acres)";
      case AppLanguage.sesotho:
        return "Boholo ba Polasi (lieka)";
    }
  }

  static String get specificLocation {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Specific Location";
      case AppLanguage.sesotho:
        return "Sebaka se Itseng";
    }
  }

  static String get cropsGrownLabel {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Crops Grown";
      case AppLanguage.sesotho:
        return "Lijalo tse Lemileng";
    }
  }

  static String fieldIsRequired(String fieldName) {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "$fieldName is required.";
      case AppLanguage.sesotho:
        return "$fieldName e hlokahala.";
    }
  }

  // Dashboard Page Strings
  static String get quickActions {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Quick Actions";
      case AppLanguage.sesotho:
        return "Liketso tse Potlakileng";
    }
  }

  static String get featuredCourses {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Featured Courses";
      case AppLanguage.sesotho:
        return "Likhofo tse Hlahelletseng";
    }
  }

  static String get topCommunityPosts {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Top Community Posts";
      case AppLanguage.sesotho:
        return "Liposo tse Holimo tsa Sechaba";
    }
  }

  static String get viewMore {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "View More";
      case AppLanguage.sesotho:
        return "Bona Tse Ling";
    }
  }

  static String get dailyFarmingTip {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Daily Farming Tip";
      case AppLanguage.sesotho:
        return "Keletso ea Temo ea Letsatsi";
    }
  }

  static String get poweredByAI {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Powered by AI";
      case AppLanguage.sesotho:
        return "E tsamaisoa ke AI";
    }
  }

  static String get offline {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Offline";
      case AppLanguage.sesotho:
        return "Ha e ntse e le sieo";
    }
  }

  static String get unableToLoadTip {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Unable to load tip";
      case AppLanguage.sesotho:
        return "Ha e khone ho jara keletso";
    }
  }

  static String get noPostsYet {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "No posts yet";
      case AppLanguage.sesotho:
        return "Ha ho liposo";
    }
  }

  static String get beFirstToShare {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Be the first to share with the community!";
      case AppLanguage.sesotho:
        return "E be oa pele ho arolelana le sechaba!";
    }
  }

  static String get noCoursesAvailable {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "No courses available";
      case AppLanguage.sesotho:
        return "Ha ho likhofo tse fumanehang";
    }
  }

  static String get today {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Today";
      case AppLanguage.sesotho:
        return "Kajeno";
    }
  }

  static String get unableToLoadWeather {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Unable to load weather";
      case AppLanguage.sesotho:
        return "Ha e khone ho jara boemo ba leholimo";
    }
  }

  static String get humidity {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Humidity";
      case AppLanguage.sesotho:
        return "Mongobo";
    }
  }

  static String get wind {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Wind";
      case AppLanguage.sesotho:
        return "Moea";
    }
  }

  static String get high {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "High";
      case AppLanguage.sesotho:
        return "Holimo";
    }
  }

  static String get addCrop {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Add Crop";
      case AppLanguage.sesotho:
        return "Eketsa Sejalo";
    }
  }

  static String get tasks {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Tasks";
      case AppLanguage.sesotho:
        return "Mesebetsi";
    }
  }

  static String get reports {
    switch (AppNotifiers.languageNotifier.value) {
      case AppLanguage.english:
        return "Reports";
      case AppLanguage.sesotho:
        return "Litlaleho";
    }
  }
}