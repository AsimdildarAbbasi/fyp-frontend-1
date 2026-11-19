class EegSample {
  final DateTime timestamp;
  final double tp9;
  final double af7;
  final double af8;
  final double tp10;
  final double aux;

  const EegSample({
    required this.timestamp,
    required this.tp9,
    required this.af7,
    required this.af8,
    required this.tp10,
    required this.aux,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch / 1000.0,
      'channels': [tp9, af7, af8, tp10, aux],
    };
  }
}

class EegBatch {
  final String? studentId;
  final int? sessionId;
  final List<EegSample> samples;

  const EegBatch({
    this.studentId,
    this.sessionId,
    required this.samples,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'session_id': sessionId,
      'samples': samples.map((s) => s.toJson()).toList(),
    };
  }
}
