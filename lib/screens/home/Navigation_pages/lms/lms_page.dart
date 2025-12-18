import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/services/lms_api_service.dart';
import 'package:agri_guide/models/tutorial.dart';
import 'package:agri_guide/widgets/tutorial_card.dart';
import 'package:agri_guide/config/theme.dart';
import 'video_player_screen.dart';
import 'my_tutorials_screen.dart';
import 'package:agri_guide/core/language/app_strings.dart';

class LMSPageContent extends StatefulWidget {
  const LMSPageContent({super.key});

  @override
  State<LMSPageContent> createState() => _LMSPageContentState();
}

class _LMSPageContentState extends State<LMSPageContent> {
  // List<Tutorial> _tutorials = [];
  List<Tutorial> _filteredTutorials = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  
  static const Map<String, String> categoryMap = {
    'all': 'All',
    'crops': 'Crops',
    'livestock': 'Livestock',
    'irrigation': 'Irrigation',
    'pest_control': 'Pest Control',
    'soil_management': 'Soil Management',
    'harvesting': 'Harvesting',
    'post_harvest': 'Post-Harvest',
    'farm_equipment': 'Farm Equipment',
    'marketing': 'Marketing',
    'other': 'Other',
  };
  
  @override
  void initState() {
    super.initState();
    _loadTutorials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isExtensionWorker() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) return false;
    
    final userType = user['user_type']?.toString().toLowerCase();
    return userType == 'extension_worker' || 
           userType == 'extension' ||
           userType == 'extensionworker';
  }

  Future<void> _loadTutorials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final apiService = LMSApiService(token);
      
      final tutorials = await apiService.getTutorials(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );

      setState(() {
        // _tutorials = tutorials;
        _filteredTutorials = tutorials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _loadTutorials();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
      _loadTutorials();
    }
  }

  Future<void> _refreshTutorials() async {
    await _loadTutorials();
  }

  void _navigateToVideoPlayer(Tutorial tutorial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(tutorial: tutorial),
      ),
    ).then((_) {
      _refreshTutorials();
    });
  }

  void _navigateToMyTutorials() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyTutorialsScreen(),
      ),
    ).then((changed) {
      if (changed == true) {
        _refreshTutorials();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isExtensionWorker = _isExtensionWorker();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.borderLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchTutorials,
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textMedium,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textMedium,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (_) => _onSearchChanged(),
          ),
          const SizedBox(height: 12),
          
          // Category filter and My Tutorials button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isDark 
                        ? AppColors.backgroundDark 
                        : AppColors.backgroundLight,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? AppColors.textWhite : AppColors.textDark,
                      ),
                      dropdownColor: isDark 
                          ? AppColors.surfaceDark 
                          : AppColors.surfaceLight,
                      style: TextStyle(
                        color: isDark ? AppColors.textWhite : AppColors.textDark,
                      ),
                      items: categoryMap.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(AppStrings.categoryLabel(entry.key)),
                        );
                      }).toList(),
                      onChanged: _onCategoryChanged,
                    ),
                  ),
                ),
              ),
              if (isExtensionWorker) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _navigateToMyTutorials,
                  icon: const Icon(Icons.video_library, size: 18),
                  label: Text(AppStrings.myTutorials),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: BorderSide(color: AppColors.lightGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.accentRed.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.errorLoadingTutorials,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTutorials,
                icon: const Icon(Icons.refresh),
                label: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTutorials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noTutorialsFound,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty || _selectedCategory != 'all'
                    ? AppStrings.tryAdjustSearch
                    : AppStrings.checkBackLater,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTutorials,
      color: AppColors.primaryGreen,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredTutorials.length,
        itemBuilder: (context, index) {
          final tutorial = _filteredTutorials[index];
          return TutorialCard(
            tutorial: tutorial,
            onTap: () => _navigateToVideoPlayer(tutorial),
          );
        },
      ),
    );
  }
}