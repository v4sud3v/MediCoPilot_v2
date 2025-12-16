/// Patient model representing a patient in the system
class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
    };
  }
}
