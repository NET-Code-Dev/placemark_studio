enum CoordinateUnits {
  dms('DMS', 'Degrees, Minutes, Seconds'),
  dd('DD', 'Decimal Degrees'),
  dmm('DMM', 'Degrees and Decimal Minutes');

  const CoordinateUnits(this.code, this.description);
  final String code;
  final String description;

  static CoordinateUnits fromCode(String code) {
    return CoordinateUnits.values.firstWhere(
      (unit) => unit.code == code,
      orElse: () => CoordinateUnits.dd,
    );
  }
}
