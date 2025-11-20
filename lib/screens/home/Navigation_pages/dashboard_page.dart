// lib/screens/home/Navigation_pages/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:agri_guide/services/weather_service.dart';
import 'package:agri_guide/services/community_api_service.dart';
import 'package:agri_guide/services/lms_api_service.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/services/farming_tip_service.dart';
import 'package:agri_guide/models/post.dart';
import 'package:agri_guide/models/tutorial.dart';
import 'package:agri_guide/widgets/post_card.dart';
import 'package:agri_guide/screens/settings_page.dart';
import 'package:agri_guide/core/language/app_strings.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardPageContent extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardPageContent({super.key, this.onNavigate});

  @override
  State<DashboardPageContent> createState() => _DashboardPageContentState();
}

class _DashboardPageContentState extends State<DashboardPageContent> {
  final WeatherService _weatherService = WeatherService();
  final FarmingTipService _farmingTipService = FarmingTipService();

  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  String? _farmingTip;
  bool _isLoadingTip = true;
  bool _isTipFallback = false;

  List<Post> _topPosts = [];
  bool _isLoadingPosts = true;

  List<Tutorial> _courses = [];
  bool _isLoadingCourses = true;
  final PageController _coursesPageController = PageController(
    viewportFraction: 0.85,
  );

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _fetchDailyTip();
    _fetchTopPosts();
    _fetchCourses();
    AppNotifiers.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _coursesPageController.dispose();
    AppNotifiers.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchWeather() async {
    setState(() => _isLoadingWeather = true);

    final data = await _weatherService.getCurrentWeather(
      city: 'Accra',
      countryCode: 'GH',
    );

    setState(() {
      _weatherData = data;
      _isLoadingWeather = false;
    });
  }

  Future<void> _fetchDailyTip() async {
    setState(() => _isLoadingTip = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final result = await _farmingTipService.getDailyFarmingTip(token);

      setState(() {
        _farmingTip = result['tip'];
        _isTipFallback = result['fallback'] ?? false;
        _isLoadingTip = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTip = false;
      });
      debugPrint('Error fetching farming tip: $e');
    }
  }

  Future<void> _fetchTopPosts() async {
    setState(() => _isLoadingPosts = true);

    try {
      final posts = await CommunityApiService.getPosts();
      setState(() {
        _topPosts = posts.take(5).toList();
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPosts = false;
      });
      debugPrint('Error fetching posts: $e');
    }
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoadingCourses = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final apiService = LMSApiService(token);
      final tutorials = await apiService.getTutorials();

      setState(() {
        _courses = tutorials.take(10).toList();
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
      debugPrint('Error fetching courses: $e');
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _fetchWeather(),
      _fetchDailyTip(),
      _fetchTopPosts(),
      _fetchCourses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder(
      valueListenable: AppNotifiers.languageNotifier,
      builder: (context, language, child) {
        return RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherWidget(),
                const SizedBox(height: 16),
                _buildFarmingTipCard(),
                const SizedBox(height: 24),
                Text(
                  AppStrings.quickActions,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                _buildQuickActionsGrid(),
                const SizedBox(height: 24),
                Text(
                  AppStrings.featuredCourses,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                _buildCoursesCarousel(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.topCommunityPosts,
                      style: theme.textTheme.headlineMedium,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        widget.onNavigate?.call(2);
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(AppStrings.viewMore),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTopPostsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFarmingTipCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [colorScheme.primary.withOpacity(0.8), colorScheme.primary]
              : [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dailyFarmingTip,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.poweredByAI,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTipFallback)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.offline,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          _isLoadingTip
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Text(
                  _farmingTip ?? AppStrings.unableToLoadTip,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTopPostsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingPosts) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (_topPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.outline.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noPostsYet,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.beFirstToShare,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _topPosts
          .map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                post: post,
                onDelete: () {
                  _fetchTopPosts();
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCoursesCarousel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingCourses) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 48,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.noCoursesAvailable,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _coursesPageController,
        scrollDirection: Axis.horizontal,
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCourseCard(course),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(Tutorial course) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        // Navigate to course details or video player
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  course.thumbnailUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.video_library,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.getFormattedViewCount(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yy').format(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingWeather
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : _weatherData == null
              ? _buildWeatherError()
              : _buildWeatherContent(formattedDate),
    );
  }

  Widget _buildWeatherError() {
    final theme = Theme.of(context);

    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.white70, size: 48),
        const SizedBox(height: 12),
        Text(
          AppStrings.unableToLoadWeather,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _fetchWeather,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
          ),
          child: Text(AppStrings.retry),
        ),
      ],
    );
  }

  Widget _buildWeatherContent(String formattedDate) {
    final theme = Theme.of(context);
    final temp = _weatherData!['main']['temp'].toDouble();
    final tempMin = _weatherData!['main']['temp_min'].toDouble();
    final tempMax = _weatherData!['main']['temp_max'].toDouble();
    final description = _weatherData!['weather'][0]['description'] as String;
    final conditionCode = _weatherData!['weather'][0]['id'] as int;
    final cityName = _weatherData!['name'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.today,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($formattedDate)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  cityName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildWeatherIcon(conditionCode),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${temp.round()}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/${tempMin.round()}°',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description
                      .split(' ')
                      .map((word) => word[0].toUpperCase() + word.substring(1))
                      .join(' '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeatherDetail(
              Icons.water_drop,
              '${_weatherData!['main']['humidity']}%',
              AppStrings.humidity,
            ),
            _buildWeatherDetail(
              Icons.air,
              '${_weatherData!['wind']['speed']} m/s',
              AppStrings.wind,
            ),
            _buildWeatherDetail(
              Icons.thermostat,
              '${tempMax.round()}°',
              AppStrings.high,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(int conditionCode) {
    final weatherType = _weatherService.getWeatherIcon(conditionCode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: _getWeatherIconWidget(weatherType),
    );
  }

  Widget _getWeatherIconWidget(String weatherType) {
    switch (weatherType) {
      case 'clear':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade400,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade300.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.wb_sunny, color: Colors.white, size: 32),
        );
      case 'clouds':
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.cloud,
              size: 56,
              color: Colors.white.withOpacity(0.9),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade300.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wb_sunny,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      case 'rain':
      case 'drizzle':
        return Icon(
          Icons.water_drop,
          size: 56,
          color: Colors.white.withOpacity(0.9),
        );
      case 'thunderstorm':
        return Icon(Icons.flash_on, size: 56, color: Colors.yellow.shade300);
      case 'snow':
        return Icon(
          Icons.ac_unit,
          size: 56,
          color: Colors.white.withOpacity(0.9),
        );
      default:
        return Icon(
          Icons.wb_cloudy,
          size: 56,
          color: Colors.white.withOpacity(0.9),
        );
    }
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  AppStrings.addCrop,
                  Icons.add_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  AppStrings.tasks,
                  Icons.checklist,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  AppStrings.reports,
                  Icons.bar_chart,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  AppStrings.settings,
                  Icons.settings,
                  Colors.orange,
                  onTap: _openSettingsPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }
}