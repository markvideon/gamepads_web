enum SupportedAxis {
  unknown,
  lhsHorizontal,
  lhsVertical(invert: true),
  rhsHorizontal,
  rhsVertical(invert: true);

  const SupportedAxis({this.invert = false});

  factory SupportedAxis.fromIndex(int idx) {
    switch (idx) {
      case 0:
        return SupportedAxis.lhsHorizontal;
      case 1:
        return SupportedAxis.lhsVertical;
      case 2:
        return SupportedAxis.rhsHorizontal;
      case 3:
        return SupportedAxis.rhsVertical;
      default:
        return SupportedAxis.unknown;
    }
  }

  final bool invert;
}