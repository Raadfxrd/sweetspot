class SweetSpotResult {
  final double leftDistance;
  final double rightDistance;
  final double speakerSpacing;
  final double listeningDistance;
  final double triangleAccuracy;
  final double suggestedToeInLeft;
  final double suggestedToeInRight;
  final bool isOptimal;
  final String feedback;

  const SweetSpotResult({
    required this.leftDistance,
    required this.rightDistance,
    required this.speakerSpacing,
    required this.listeningDistance,
    required this.triangleAccuracy,
    required this.suggestedToeInLeft,
    required this.suggestedToeInRight,
    required this.isOptimal,
    required this.feedback,
  });

  double get averageListeningDistance =>
      (leftDistance + rightDistance) / 2;

  double get symmetryRatio {
    if (rightDistance == 0) return 0;
    final ratio = leftDistance / rightDistance;
    return ratio > 1 ? 1 / ratio : ratio;
  }

  @override
  String toString() =>
      'SweetSpotResult(accuracy: ${(triangleAccuracy * 100).toStringAsFixed(1)}%, '
      'L: ${leftDistance.toStringAsFixed(2)}m, '
      'R: ${rightDistance.toStringAsFixed(2)}m, '
      'spacing: ${speakerSpacing.toStringAsFixed(2)}m)';
}
