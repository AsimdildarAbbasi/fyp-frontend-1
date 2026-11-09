import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/voice_profile.dart';
import '../../services/voice_service.dart';
import '../../network/network_manager.dart';
import 'constants.dart';

void showAdvisorVoiceSettings(BuildContext context, {VoidCallback? onVoiceSaved}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (ctx) => AdvisorVoiceSettingsSheet(onSaved: onVoiceSaved),
  );
}

class AdvisorVoiceSettingsSheet extends StatefulWidget {
  final VoidCallback? onSaved;
  final bool isFullScreen;

  const AdvisorVoiceSettingsSheet({
    super.key,
    this.onSaved,
    this.isFullScreen = false,
  });

  @override
  State<AdvisorVoiceSettingsSheet> createState() => _AdvisorVoiceSettingsSheetState();
}

class _AdvisorVoiceSettingsSheetState extends State<AdvisorVoiceSettingsSheet>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<VoiceProfile> _profiles = [];
  VoiceProfile? _selectedProfile;
  double _selectedRate = 1.0;

  bool _isLoadingVoices = true;
  bool _isLoadingAudio = false;
  bool _isPlaying = false;
  bool _isSaving = false;
  String? _errorMessage;

  int _currentSeconds = 0;
  int _totalSeconds = 8;
  Timer? _playbackTimer;
  late AnimationController _waveAnimController;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _completeSub;

  final List<double> _waveformHeights = const [
    6, 12, 18, 10, 16, 22, 14, 20, 8, 14, 18, 12, 20, 16, 10, 18, 14, 8, 12, 18, 10, 15,
  ];

  @override
  void initState() {
    super.initState();

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _waveAnimController.reverse();
        } else if (status == AnimationStatus.dismissed && _isPlaying) {
          _waveAnimController.forward();
        }
      });

    // Listen to real AudioPlayer events
    _posSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _currentSeconds = pos.inSeconds;
        });
      }
    });

    _durSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted && dur.inSeconds > 0) {
        setState(() {
          _totalSeconds = dur.inSeconds;
        });
      }
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      _stopPlayback();
    });

    _loadDataFromBackendAndPrefs();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _playbackTimer?.cancel();
    try {
      _audioPlayer.dispose();
    } catch (_) {}
    _waveAnimController.dispose();
    super.dispose();
  }

  String _resolveAudioUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final base = NetworkManager.baseURL;
    final domain =
        base.endsWith('/api') ? base.substring(0, base.length - 4) : base;

    if (cleanPath.startsWith('/api/')) {
      return '$domain$cleanPath';
    }
    return '$domain/api$cleanPath';
  }

  Future<void> _loadDataFromBackendAndPrefs() async {
    setState(() {
      _isLoadingVoices = true;
      _errorMessage = null;
    });

    String? preferredVoiceId;

    try {
      final prefs = await SharedPreferences.getInstance();
      preferredVoiceId = prefs.getString('preferred_voice_id');
      final savedRate = prefs.getDouble('preferred_speech_rate');
      final studentId = prefs.getString('student_id');

      if (savedRate != null) {
        setState(() {
          _selectedRate = savedRate;
        });
      }

      // 1. Fetch student preference from real backend if student is logged in
      if (studentId != null && studentId.isNotEmpty) {
        try {
          final remotePref = await _voiceService.getStudentVoicePreference(studentId);
          if (remotePref != null && remotePref.isNotEmpty) {
            preferredVoiceId = remotePref;
          }
        } catch (_) {}
      }

      // 2. Fetch available voices dynamically from backend API: GET /api/voices
      final voicesPayload = await _voiceService.fetchAvailableVoices();
      if (voicesPayload != null && mounted) {
        final defaultSampleText = voicesPayload['default_sample_text']?.toString();
        final recRaw = voicesPayload['recommended_voices'];
        final allRaw = voicesPayload['all_voices'];

        List<VoiceProfile> remoteProfiles = [];
        if (recRaw is List && recRaw.isNotEmpty) {
          remoteProfiles = recRaw
              .whereType<Map<String, dynamic>>()
              .map((item) => VoiceProfile.fromJson(item, defaultSampleText: defaultSampleText))
              .toList();
        }

        // Augment with non-duplicate voices from all_voices
        if (allRaw is List) {
          final existingIds = remoteProfiles.map((p) => p.id.toLowerCase()).toSet();
          for (final item in allRaw) {
            if (item is Map<String, dynamic>) {
              final profile = VoiceProfile.fromJson(item, defaultSampleText: defaultSampleText);
              if (!existingIds.contains(profile.id.toLowerCase())) {
                remoteProfiles.add(profile);
                existingIds.add(profile.id.toLowerCase());
              }
            }
            if (remoteProfiles.length >= 10) break;
          }
        }

        if (remoteProfiles.isNotEmpty) {
          _profiles = remoteProfiles;

          // Match selected profile with loaded preference or default voice
          VoiceProfile? matched;
          if (preferredVoiceId != null) {
            matched = _profiles.firstWhereOrNull(
              (p) =>
                  p.id.toLowerCase() == preferredVoiceId!.toLowerCase() ||
                  p.name.toLowerCase() == preferredVoiceId.toLowerCase(),
            );
          }

          final backendDefault = voicesPayload['default_voice']?.toString();
          if (matched == null && backendDefault != null) {
            matched = _profiles.firstWhereOrNull(
              (p) =>
                  p.id.toLowerCase() == backendDefault.toLowerCase() ||
                  p.name.toLowerCase() == backendDefault.toLowerCase(),
            );
          }

          _selectedProfile = matched ?? _profiles.first;
        } else {
          _errorMessage = "No voice profiles returned by backend.";
        }
      } else {
        _errorMessage = "Could not connect to backend voices service.";
      }
    } catch (e) {
      debugPrint("Error loading voice profiles from backend: $e");
      _errorMessage = "Failed to load voice profiles: $e";
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVoices = false;
        });
      }
    }
  }

  void _toggleAuditionPlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    final profile = _selectedProfile;
    if (profile == null) return;

    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = true;
      _isLoadingAudio = true;
      if (_currentSeconds >= _totalSeconds) {
        _currentSeconds = 0;
      }
    });

    _waveAnimController.forward();

    try {
      // 1. Synthesize audio preview via real backend API: POST /api/voices/test
      String? audioPath;
      final testResult = await _voiceService.testVoice(
        profile.id,
        text: profile.sampleText,
      );

      if (testResult != null && testResult['audio_url'] != null) {
        audioPath = testResult['audio_url'].toString();
        if (testResult['duration_ms'] is num) {
          final dur = ((testResult['duration_ms'] as num).toDouble() / 1000).ceil();
          if (dur > 0 && mounted) {
            setState(() {
              _totalSeconds = dur;
            });
          }
        }
      }

      // 2. Fallback to GET /api/voices/preview endpoint if test didn't return url
      if (audioPath == null || audioPath.isEmpty) {
        audioPath = profile.sampleUrl ??
            '/api/voices/preview?voice=${Uri.encodeComponent(profile.id)}';
      }

      final fullUrl = _resolveAudioUrl(audioPath);
      await _audioPlayer.stop();
      await _audioPlayer.setPlaybackRate(_selectedRate);
      await _audioPlayer.play(UrlSource(fullUrl));

      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
      }
    } catch (e) {
      debugPrint("Audition playback error: $e");
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
      }
      _startSimulatedFallbackTimer();
    }
  }

  void _startSimulatedFallbackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_currentSeconds < _totalSeconds) {
        setState(() {
          _currentSeconds++;
        });
      } else {
        _stopPlayback();
      }
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    try {
      _audioPlayer.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isLoadingAudio = false;
        if (_currentSeconds >= _totalSeconds) {
          _currentSeconds = 0;
        }
      });
      _waveAnimController.stop();
    }
  }

  void _setSpeechRate(double rate) {
    setState(() {
      _selectedRate = rate;
    });
    if (_isPlaying) {
      try {
        _audioPlayer.setPlaybackRate(rate);
      } catch (_) {}
    }
  }

  Future<void> _savePreferences() async {
    final profile = _selectedProfile;
    if (profile == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_voice_id', profile.id);
      await prefs.setString('preferred_voice_name', profile.name);
      await prefs.setString('preferred_voice_tag', profile.tag);
      await prefs.setDouble('preferred_speech_rate', _selectedRate);

      final studentId = prefs.getString('student_id');
      if (studentId != null && studentId.isNotEmpty) {
        // Save to real backend database via PUT /api/student/{student_id}/voice-preference
        await _voiceService.updateStudentVoicePreference(
          studentId,
          profile.id,
        );
      }
    } catch (e) {
      debugPrint("Error saving voice preferences: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    widget.onSaved?.call();

    if (mounted) {
      Get.snackbar(
        "Voice Profile Saved",
        "Preferred advisor voice set to ${profile.name} (${profile.accent}) at ${_selectedRate}x speed.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0B1C2D),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E)),
      );

      if (!widget.isFullScreen && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString();
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final profile = _selectedProfile;

    final content = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                children: [
                  const Text(
                    "Advisor Voice Settings",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 13,
                          color: Color(0xFF0284C7),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "AI TTS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                "Select your preferred AI advisor voice for speech responses",
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),

              if (_isLoadingVoices && _profiles.isEmpty)
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                      SizedBox(height: 14),
                      Text(
                        "Connecting to backend voices...",
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                )
              else if (_errorMessage != null && _profiles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadDataFromBackendAndPrefs,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text("Retry Connection"),
                      ),
                    ],
                  ),
                )
              else ...[
                // Available Voice Profiles Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "AVAILABLE VOICE PROFILES",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      "${_profiles.length} Available",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horizontal Voice Cards Carousel
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _profiles.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = _profiles[index];
                      final isSelected = profile != null && item.id == profile.id;

                      return GestureDetector(
                        onTap: () {
                          if (_isPlaying) {
                            _stopPlayback();
                          }
                          setState(() {
                            _selectedProfile = item;
                            _currentSeconds = 0;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 118,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF245C94)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF245C94).withOpacity(0.12)
                                    : Colors.black.withOpacity(0.03),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF245C94)
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                  if (item.isRecommended) ...[
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFEAB308),
                                      size: 14,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.accent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Audition Speech Sample Card
                if (profile != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: blue indicator + title + tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0284C7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Audition Speech Sample",
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile.tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Speech Bubble
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF245C94),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      profile.sampleText,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.45,
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Tone: ${profile.tone}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "Speed: ${_selectedRate}x • Pitch: ${profile.pitch}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Audio Playback Row
                        Row(
                          children: [
                            // Play/Pause button
                            GestureDetector(
                              onTap: _toggleAuditionPlayback,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B1C2D),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0B1C2D).withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: _isLoadingAudio
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        _isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Waveform visualizer bars
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _waveAnimController,
                                builder: (context, _) {
                                  final progressRatio = _totalSeconds > 0
                                      ? (_currentSeconds / _totalSeconds).clamp(0.0, 1.0)
                                      : 0.0;
                                  final activeIndex =
                                      (progressRatio * _waveformHeights.length).floor();

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: List.generate(
                                      _waveformHeights.length,
                                      (i) {
                                        final baseH = _waveformHeights[i];
                                        final animFactor = _isPlaying
                                            ? 0.7 +
                                                0.6 *
                                                    ((i % 2 == 0)
                                                        ? _waveAnimController.value
                                                        : (1 - _waveAnimController.value))
                                            : 1.0;
                                        final h = (baseH * animFactor).clamp(4.0, 26.0);
                                        final isBarActive = i <= activeIndex && _currentSeconds > 0;

                                        return Container(
                                          width: 3.2,
                                          height: h,
                                          decoration: BoxDecoration(
                                            color: isBarActive
                                                ? const Color(0xFF245C94)
                                                : const Color(0xFFCBD5E1),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Timestamp
                            Text(
                              "${_formatTime(_currentSeconds)} / ${_formatTime(_totalSeconds)}",
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Speech Rate Selector Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Speech Rate",
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [0.9, 1.0, 1.2].map((rate) {
                          final isSelected = (_selectedRate - rate).abs() < 0.05;
                          return GestureDetector(
                            onTap: () => _setSpeechRate(rate),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0B1C2D)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                "${rate}x",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save as Preferred Voice Button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppGradients.mainGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1C2D).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_isSaving || profile == null) ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Save as Preferred Voice",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFE6ECF2),
        appBar: AppBar(
          title: const Text(
            "Profile",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          backgroundColor: const Color(0xFFE6ECF2),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: content,
      );
    }

    return content;
  }
}
