import 'package:flutter/material.dart';
import 'package:agri_guide/services/ai_services/tts_service.dart';

/// Optional TTS Settings Page
/// Allows users to customize voice parameters
class TTSSettingsPage extends StatefulWidget {
  const TTSSettingsPage({super.key});

  @override
  State<TTSSettingsPage> createState() => _TTSSettingsPageState();
}

class _TTSSettingsPageState extends State<TTSSettingsPage> {
  final TTSService _ttsService = TTSService();
  
  double _volume = 0.8;
  double _pitch = 1.0;
  double _speechRate = 0.5;
  
  List<Map<String, String>> _availableVoices = [];
  Map<String, String>? _selectedVoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _ttsService.initialize();
    
    setState(() {
      _volume = _ttsService.volume;
      _pitch = _ttsService.pitch;
      _speechRate = _ttsService.speechRate;
    });

    // Load available voices
    final voices = await _ttsService.getAvailableVoices();
    
    setState(() {
      _availableVoices = voices;
      _isLoading = false;
    });
  }

  Future<void> _testVoice() async {
    await _ttsService.speak(
      'This is a test of the text to speech voice settings.',
      language: 'english',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Volume Control
                _buildSettingCard(
                  context,
                  title: 'Volume',
                  icon: Icons.volume_up,
                  child: Column(
                    children: [
                      Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(_volume * 100).round()}%',
                        onChanged: (value) {
                          setState(() => _volume = value);
                          _ttsService.setVolume(value);
                        },
                      ),
                      Text(
                        '${(_volume * 100).round()}%',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Pitch Control
                _buildSettingCard(
                  context,
                  title: 'Pitch',
                  icon: Icons.graphic_eq,
                  child: Column(
                    children: [
                      Slider(
                        value: _pitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: _pitch.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => _pitch = value);
                          _ttsService.setPitch(value);
                        },
                      ),
                      Text(
                        _pitch.toStringAsFixed(1),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Speech Rate Control
                _buildSettingCard(
                  context,
                  title: 'Speech Rate',
                  icon: Icons.speed,
                  child: Column(
                    children: [
                      Slider(
                        value: _speechRate,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: _speechRate.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => _speechRate = value);
                          _ttsService.setSpeechRate(value);
                        },
                      ),
                      Text(
                        _speechRate.toStringAsFixed(1),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Available Voices
                if (_availableVoices.isNotEmpty)
                  _buildSettingCard(
                    context,
                    title: 'Voice Selection',
                    icon: Icons.record_voice_over,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_availableVoices.length} voices available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_availableVoices.take(5).map((voice) {
                          final name = voice['name'] ?? 'Unknown';
                          final locale = voice['locale'] ?? '';
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Radio<Map<String, String>>(
                              value: voice,
                              groupValue: _selectedVoice,
                              onChanged: (value) {
                                setState(() => _selectedVoice = value);
                                if (value != null) {
                                  _ttsService.setVoice(value);
                                }
                              },
                            ),
                            title: Text(name),
                            subtitle: Text(locale),
                            onTap: () {
                              setState(() => _selectedVoice = voice);
                              _ttsService.setVoice(voice);
                            },
                          );
                        })),
                        if (_availableVoices.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+ ${_availableVoices.length - 5} more voices',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Test Button
                ElevatedButton.icon(
                  onPressed: _testVoice,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Voice'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Reset Button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _volume = 0.8;
                      _pitch = 1.0;
                      _speechRate = 0.5;
                      _selectedVoice = null;
                    });
                    _ttsService.setVolume(0.8);
                    _ttsService.setPitch(1.0);
                    _ttsService.setSpeechRate(0.5);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Settings reset to defaults'),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Defaults'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Card
                Card(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About Voice Settings',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Volume: Controls how loud the voice speaks\n'
                          '• Pitch: Changes the tone (higher/lower)\n'
                          '• Speech Rate: Adjusts speaking speed\n'
                          '• Voice: Select different voice types',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}