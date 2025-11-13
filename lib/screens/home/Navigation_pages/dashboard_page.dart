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
  }

  @override
  void dispose() {
    _coursesPageController.dispose();
    super.dispose();
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
    print('🌾 ============================================');
    print('🌾 DASHBOARD - Fetching Daily Tip');
    print('🌾 ============================================');

    setState(() => _isLoadingTip = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      // print('🔑 Token present: ${token != null}');

      if (token == null) {
        // print('❌ No token - user not authenticated');
        throw Exception('Not authenticated');
      }

      // print('📡 Calling FarmingTipService...');
      final result = await _farmingTipService.getDailyFarmingTip(token);

      // print('✅ Got result from service');
      // print('📝 Result: $result');

      setState(() {
        _farmingTip = result['tip'];
        _isTipFallback = result['fallback'] ?? false;
        _isLoadingTip = false;
      });

      // print('✅ State updated successfully');
      // print('📝 Tip: ${_farmingTip?.substring(0, 50)}...');
      // print('🔄 Is fallback: $_isTipFallback');
    } catch (e) {
      // print('🌾 ============================================');
      // print('🚨 DASHBOARD - Error fetching tip');
      // print('🌾 ============================================');
      // print('❌ Error: $e');

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
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Widget
            _buildWeatherWidget(),
            const SizedBox(height: 16),

            // AI Farming Tip Card
            _buildFarmingTipCard(),
            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),

            // Learning Carousel Section
            const Text(
              'Featured Courses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCoursesCarousel(),
            const SizedBox(height: 24),

            // Top Community Posts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Community Posts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    widget.onNavigate?.call(2);
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View More'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
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
  }

  Widget _buildFarmingTipCard() {
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade700.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Farming Tip',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Powered by AI',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
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
                  child: const Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),

          // Tip Content
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
                  _farmingTip ?? 'Unable to load tip',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTopPostsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingPosts) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_topPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.shade200,
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
              color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to share with the community!',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[500] : Colors.grey.shade500,
              ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingCourses) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: Colors.green.shade700),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 48,
                color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No courses available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                ),
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
            // Background Image
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade600,
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
            // Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
            // Course details
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
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
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
                          style: TextStyle(
                            fontSize: 12,
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
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.white70, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Unable to load weather',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _fetchWeather,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildWeatherContent(String formattedDate) {
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
                const Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($formattedDate)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
              'Humidity',
            ),
            _buildWeatherDetail(
              Icons.air,
              '${_weatherData!['wind']['speed']} m/s',
              'Wind',
            ),
            _buildWeatherDetail(
              Icons.thermostat,
              '${tempMax.round()}°',
              'High',
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
            Icon(Icons.cloud, size: 56, color: Colors.white.withOpacity(0.9)),
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
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.shade200,
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
                  'Add Crop',
                  Icons.add_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Tasks',
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
                  'Reports',
                  Icons.bar_chart,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Settings',
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
