/// Vitals model representing patient vital signs
class Vitals {
  final double? temperature;
  final int? heartRate;
  final int? spO2;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? respiratoryRate;

  const Vitals({
    this.temperature,
    this.heartRate,
    this.spO2,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.respiratoryRate,
  });

  factory Vitals.fromJson(Map<String, dynamic> json) {
    return Vitals(
      temperature: json['temperature']?.toDouble(),
      heartRate: json['heartRate'] as int?,
      spO2: json['spO2'] as int?,
      bloodPressureSystolic: json['bloodPressureSystolic'] as int?,
      bloodPressureDiastolic: json['bloodPressureDiastolic'] as int?,
      respiratoryRate: json['respiratoryRate'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'heartRate': heartRate,
      'spO2': spO2,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'respiratoryRate': respiratoryRate,
    };
  }

  bool get hasData =>
      temperature != null ||
      heartRate != null ||
      spO2 != null ||
      bloodPressureSystolic != null ||
      respiratoryRate != null;
}
