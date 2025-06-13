class User {
  final int id;
  final String email;
  final String username;
  final String postalCode;
  final int? age;
  final String? sex;
  final double? height;
  final double? weight;
  final double? bmi;
  final bool isHelper;
  final bool isDeaf;
  final bool isBlind;
  final bool isWheelchairBound;
  final bool canAssistDeaf;
  final bool canAssistBlind;
  final bool canAssistWheelchair;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.postalCode,
    this.age,
    this.sex,
    this.height,
    this.weight,
    this.bmi,
    required this.isHelper,
    required this.isDeaf,
    required this.isBlind,
    required this.isWheelchairBound,
    required this.canAssistDeaf,
    required this.canAssistBlind,
    required this.canAssistWheelchair,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      postalCode: map['postalCode'],
      age: map['age'],
      sex: map['sex'],
      height: map['height'],
      weight: map['weight'],
      bmi: map['bmi'],
      isHelper: map['isHelper'] == 1,
      isDeaf: map['isDeaf'] == 1,
      isBlind: map['isBlind'] == 1,
      isWheelchairBound: map['isWheelchairBound'] == 1,
      canAssistDeaf: map['canAssistDeaf'] == 1,
      canAssistBlind: map['canAssistBlind'] == 1,
      canAssistWheelchair: map['canAssistWheelchair'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'postalCode': postalCode,
      'age': age,
      'sex': sex,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'isHelper': isHelper ? 1 : 0,
      'isDeaf': isDeaf ? 1 : 0,
      'isBlind': isBlind ? 1 : 0,
      'isWheelchairBound': isWheelchairBound ? 1 : 0,
      'canAssistDeaf': canAssistDeaf ? 1 : 0,
      'canAssistBlind': canAssistBlind ? 1 : 0,
      'canAssistWheelchair': canAssistWheelchair ? 1 : 0,
    };
  }
}
class Request {
  final int id;
  final String service;
  final String date;
  final String time;
  final String location;
  final int? helperId;
  final int requesterId;
  final String status;
  final String requestType; 
  final DateTime? acceptedAt;
  final DateTime createdAt;

  Request({
    required this.id,
    required this.service,
    required this.date,
    required this.time,
    required this.location,
    this.helperId,
    required this.requesterId,
    this.status = 'pending',
    this.requestType = 'immediate',
    this.acceptedAt,
    required this.createdAt,
  });

  factory Request.fromMap(Map<String, dynamic> map) {
    return Request(
      id: map['id'],
      service: map['service'],
      date: map['date'],
      time: map['time'],
      location: map['location'],
      helperId: map['helperId'],
      requesterId: map['requesterId'],
      status: map['status'],
      requestType: map['requestType'] ?? 'immediate',
      acceptedAt: map['acceptedAt'] != null 
          ? DateTime.parse(map['acceptedAt']) 
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service': service,
      'date': date,
      'time': time,
      'location': location,
      'helperId': helperId,
      'requesterId': requesterId,
      'status': status,
      'requestType': requestType,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isImmediate => requestType == 'immediate';
  bool get isScheduled => requestType == 'scheduled';
  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
}

