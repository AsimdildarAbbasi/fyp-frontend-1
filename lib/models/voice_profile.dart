class VoiceProfile {
  final String id;
  final String name;
  final String tag;
  final String accent;
  final String tone;
  final String pitch;
  final String sampleText;
  final String? sampleUrl;
  final double defaultSpeed;
  final bool isRecommended;

  const VoiceProfile({
    required this.id,
    required this.name,
    required this.tag,
    required this.accent,
    required this.tone,
    this.pitch = "Natural",
    required this.sampleText,
    this.sampleUrl,
    this.defaultSpeed = 1.0,
    this.isRecommended = true,
  });

  factory VoiceProfile.fromJson(
    Map<String, dynamic> json, {
    String? defaultSampleText,
  }) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? id;
    final displayName = json['display_name']?.toString() ?? name;
    final category = json['category']?.toString() ?? '';
    final language = json['language']?.toString() ?? '';
    final gender = json['gender']?.toString() ?? 'Natural';
    final sampleUrl = json['sample_url']?.toString();
    final isRecommended = json['is_recommended'] == true;

    // Build friendly accent / category label
    String accent = category;
    if (accent.isEmpty || accent == 'General') {
      accent = language.isNotEmpty ? language : 'General';
    }

    return VoiceProfile(
      id: id,
      name: name,
      tag: displayName,
      accent: accent,
      tone: gender == 'Female'
          ? 'Clear & Friendly'
          : (gender == 'Male' ? 'Professional & Calm' : 'Natural'),
      pitch: "Natural",
      sampleText: defaultSampleText ??
          "Assalamu alaikum, main aap ka university advisor hoon. Main aap ki madad kar sakta hoon.",
      sampleUrl: sampleUrl,
      isRecommended: isRecommended,
    );
  }
}
