class Student {
  final int? id;
  final String firstName;
  final String middleInitial;
  final String lastName;
  final String program;
  final String school;
  final String ojtHours;
  final String startDate;
  final String endDate;
  final String office;
  final String address;
  String? qrLink;
  bool isSelected;
  final DateTime createdAt;

  Student({
    this.id,
    required this.firstName,
    required this.middleInitial,
    required this.lastName,
    required this.program,
    required this.school,
    required this.ojtHours,
    required this.startDate,
    required this.endDate,
    required this.office,
    required this.address,
    this.qrLink,
    this.isSelected = false,
    required this.createdAt,
  });

  // Add the copyWith method
  Student copyWith({
    int? id,
    String? firstName,
    String? middleInitial,
    String? lastName,
    String? program,
    String? school,
    String? ojtHours,
    String? startDate,
    String? endDate,
    String? office,
    String? address,
    String? qrLink,
    bool? isSelected,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleInitial: middleInitial ?? this.middleInitial,
      lastName: lastName ?? this.lastName,
      program: program ?? this.program,
      school: school ?? this.school,
      ojtHours: ojtHours ?? this.ojtHours,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      office: office ?? this.office,
      address: address ?? this.address,
      qrLink: qrLink ?? this.qrLink,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      firstName: map['first_name'] as String,
      middleInitial: map['middle_initial'] as String,
      lastName: map['last_name'] as String,
      program: map['program'] as String,
      school: map['school'] as String,
      ojtHours: map['ojt_hours'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      office: map['office'] as String,
      address: map['address'] as String,
      qrLink: map['qr_link'] as String?,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_initial': middleInitial,
      'last_name': lastName,
      'program': program,
      'school': school,
      'ojt_hours': ojtHours,
      'start_date': startDate,
      'end_date': endDate,
      'office': office,
      'address': address,
      'qr_link': qrLink,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
