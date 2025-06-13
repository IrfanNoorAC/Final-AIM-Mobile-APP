

import 'dart:math';

import 'package:aimapp/distance_calculator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  factory DatabaseHelper() => _instance;
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'aim_app_database31120001.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        username TEXT,
        password TEXT,
        postalCode TEXT,
        age INTEGER,
        sex TEXT,
        height REAL,
        weight REAL,
        bmi REAL,
        isHelper INTEGER DEFAULT 0,
        isDeaf INTEGER DEFAULT 0,
        isBlind INTEGER DEFAULT 0,
        isWheelchairBound INTEGER DEFAULT 0,
        canAssistDeaf INTEGER DEFAULT 0,
        canAssistBlind INTEGER DEFAULT 0,
        canAssistWheelchair INTEGER DEFAULT 0,
        latitude REAL,  
        longitude REAL 
      )
    ''');
    
    await db.execute('''
      CREATE TABLE requests(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    service TEXT,
    date TEXT,
    time TEXT,
    location TEXT,
    helperId INTEGER,
    requesterId INTEGER,
    status TEXT DEFAULT 'pending',
    requestType TEXT DEFAULT 'immediate',  
    acceptedAt TEXT,  
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(helperId) REFERENCES users(id),
    FOREIGN KEY(requesterId) REFERENCES users(id)
  )
    ''');
    
    await db.execute('''
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderId INTEGER,
        receiverId INTEGER,
        text TEXT,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(senderId) REFERENCES users(id),
        FOREIGN KEY(receiverId) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN height REAL');
      await db.execute('ALTER TABLE users ADD COLUMN weight REAL');
      await db.execute('ALTER TABLE users ADD COLUMN bmi REAL');
    }
    if (oldVersion < 3) {
      
    }
    if (oldVersion < 4) {
      
    }
  }
Future<void> cancelRequest(int requestId) async {
  final db = await database;
  await db.delete(
    'requests',
    where: 'id = ?',
    whereArgs: [requestId],
  );
}
  // User CRUD Operations
  Future<int> insertUser({
    required String email,
    required String username,
    required String password,
    String? postalCode,
    int? age,
    String? sex,
    double? height,
    double? weight,
    double? bmi,
    bool isHelper = false,
    bool isDeaf = false,
    bool isBlind = false,
    bool isWheelchairBound = false,
    bool canAssistDeaf = false,
    bool canAssistBlind = false,
    bool canAssistWheelchair = false,
  }) async {
    final db = await database;
    return await db.insert(
      'users',
      {
        'email': email,
        'username': username,
        'password': password,
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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return users.isNotEmpty ? users.first : null;
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return users.isNotEmpty ? users.first : null;
  }
Future<List<Map<String, dynamic>>> getPendingScheduledRequests({
  required int helperId,
  required String postalCode,
  bool? canAssistDeaf,
  bool? canAssistBlind,
  bool? canAssistWheelchair,
}) async {
  final db = await database;
  
  // Get helper's location
  final helperLocation = await DistanceCalculator.getLocationDetails(postalCode);
  
  // Build query to find matching pending requests
  final query = '''
    SELECT requests.*, users.*,
      (ABS(users.latitude - ?) + ABS(users.longitude - ?)) AS distance,
      requests.id AS requestId
    FROM requests
    JOIN users ON requests.requesterId = users.id
    WHERE requests.requestType = 'scheduled'
      AND requests.status = 'pending'
      AND requests.helperId IS NULL
      ${canAssistDeaf == true ? 'AND (users.isDeaf = 1 OR requests.service LIKE "%Deaf%")' : ''}
      ${canAssistBlind == true ? 'AND (users.isBlind = 1 OR requests.service LIKE "%Blind%")' : ''}
      ${canAssistWheelchair == true ? 'AND (users.isWheelchairBound = 1 OR requests.service LIKE "%Wheelchair%")' : ''}
    ORDER BY distance ASC
  ''';
  
  return await db.rawQuery(query, [
    helperLocation['latitude'],
    helperLocation['longitude'],
  ]);
}
Future<List<Map<String, dynamic>>> getScheduledRequestsByHelper(int helperId) async {
  final db = await database;
  return await db.query(
    'requests',
    where: 'helperId = ? AND requestType = ?',
    whereArgs: [helperId, 'scheduled'],
    orderBy: 'date, time',
  );
}

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }
// Enhanced Helper Search Methods
  Future<List<Map<String, dynamic>>> getRankedHelpers({
    required int requesterId,
    required String postalCode,
    required bool needsDeafAssistance,
    required bool needsBlindAssistance,
    required bool needsWheelchairAssistance,
  }) async {
    
    // Get requester profile
    final requester = await getUser(requesterId);
    if (requester == null) return [];
    
    // Get nearby helpers (filtered by capabilities)
    final helpers = await getNearbyHelpers(
      postalCode: postalCode,
      userId: requesterId,
      needsDeafAssistance: needsDeafAssistance,
      needsBlindAssistance: needsBlindAssistance,
      needsWheelchairAssistance: needsWheelchairAssistance,
    );
    
    // Calculate scores for each helper
    final rankedHelpers = await Future.wait(helpers.map((helper) async {
      // Get distance information
      final distanceInfo = await DistanceCalculator.getDistanceAndTime(
        postalCode,
        helper['postalCode'],
      );
      
      // Calculate compatibility score
      final score = _calculateCompatibilityScore(
        requester: requester,
        helper: helper,
        distanceKm: distanceInfo['distance'],
      );
      
      return {
        ...helper,
        'score': score,
        'distance': distanceInfo['distance'],
        'distanceText': distanceInfo['distanceText'],
        'timeText': distanceInfo['timeText'],
      };
    }));
    
    // Sort by score (descending)
    rankedHelpers.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    return rankedHelpers;
  }

  double _calculateCompatibilityScore({
    required Map<String, dynamic> requester,
    required Map<String, dynamic> helper,
    required double distanceKm,
  }) {
    double score = 0;
    
    // 1. Disability/Capability Matching (50% weight)
    if (requester['isDeaf'] == 1 && helper['canAssistDeaf'] == 1) {
      score += 20; // Max 20 points
    }
    
    if (requester['isBlind'] == 1 && helper['canAssistBlind'] == 1) {
      score += 20; // Max 20 points
    }
    
    if (requester['isWheelchairBound'] == 1 && helper['canAssistWheelchair'] == 1) {
      score += 20; // Max 20 points
    }
    
    // 2. Physical Compatibility (30% weight)
    // Gender preference
    if (requester['sex'] == helper['sex']) {
      score += 5; // Max 5 points
    }
    
    // Height compatibility (helpers taller than requesters get bonus)
    final requesterHeight = requester['height'] ?? 0;
    final helperHeight = helper['height'] ?? 0;
    if (helperHeight > requesterHeight) {
      score += min(5 * (helperHeight - requesterHeight) / 10, 5); // Max 5 points
    }
    
    // BMI compatibility (closer BMIs get bonus)
    final requesterBMI = requester['bmi'] ?? 0;
    final helperBMI = helper['bmi'] ?? 0;
    final bmiDifference = (helperBMI - requesterBMI).abs();
    score += max(0, 10 - min(bmiDifference, 10)); // Max 10 points
    
    // 3. Proximity (20% weight)
    if (distanceKm <= 5) {
      score += 20;
    } else if (distanceKm <= 10) {
      score += 15;
    } else if (distanceKm <= 20) {
      score += 10;
    } else {
      score += 5;
    }
    
    // Ensure score doesn't exceed 100
    return min(score, 100);
  }
  

Future<List<Map<String, dynamic>>> getRankedRequesters({
  required int helperId,
  required String postalCode,
  required bool canAssistDeaf,
  required bool canAssistBlind,
  required bool canAssistWheelchair,
}) async {
  
  // Get helper profile
  final helper = await getUser(helperId);
  if (helper == null) return [];
  
  // Get nearby requesters (filtered by needs)
  final requesters = await getNearbyRequests(
    postalCode: postalCode,
    userId: helperId,
    canAssistDeaf: canAssistDeaf,
    canAssistBlind: canAssistBlind,
    canAssistWheelchair: canAssistWheelchair,
  );
  
  // Calculate scores for each requester
  final rankedRequesters = await Future.wait(requesters.map((requester) async {
    // Get distance information
    final distanceInfo = await DistanceCalculator.getDistanceAndTime(
      postalCode,
      requester['postalCode'],
    );
    
    // Calculate compatibility score
    final score = _calculateReverseCompatibilityScore(
      helper: helper,
      requester: requester,
      distanceKm: distanceInfo['distance'],
    );
    
    return {
      ...requester,
      'score': score,
      'distance': distanceInfo['distance'],
      'distanceText': distanceInfo['distanceText'],
      'timeText': distanceInfo['timeText'],
    };
  }));
  
  // Sort by score (descending)
  rankedRequesters.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  
  return rankedRequesters;
}

double _calculateReverseCompatibilityScore({
  required Map<String, dynamic> helper,
  required Map<String, dynamic> requester,
  required double distanceKm,
}) {
  double score = 0;
  
  // 1. Capability/Needs Matching (50% weight)
  if (helper['canAssistDeaf'] == 1 && requester['isDeaf'] == 1) {
    score += 20; // Max 20 points
  }
  
  if (helper['canAssistBlind'] == 1 && requester['isBlind'] == 1) {
    score += 20; // Max 20 points
  }
  
  if (helper['canAssistWheelchair'] == 1 && requester['isWheelchairBound'] == 1) {
    score += 20; // Max 20 points
  }
  
  // 2. Physical Compatibility (30% weight)
  // Gender preference
  if (helper['sex'] == requester['sex']) {
    score += 5; // Max 5 points
  }
  
  // Height compatibility (helpers should be taller than requesters for mobility)
  final helperHeight = helper['height'] ?? 0;
  final requesterHeight = requester['height'] ?? 0;
  if (helperHeight > requesterHeight) {
    score += min(5 * (helperHeight - requesterHeight) / 10, 5); // Max 5 points
  }
  
  // BMI compatibility (similar BMIs better for physical tasks)
  final helperBMI = helper['bmi'] ?? 0;
  final requesterBMI = requester['bmi'] ?? 0;
  final bmiDifference = (helperBMI - requesterBMI).abs();
  score += max(0, 10 - min(bmiDifference, 10)); // Max 10 points
  
  // 3. Proximity (20% weight)
  if (distanceKm <= 5) {
    score += 20;
  } else if (distanceKm <= 10) {
    score += 15;
  } else if (distanceKm <= 20) {
    score += 10;
  } else {
    score += 5;
  }
  
  // Ensure score doesn't exceed 100
  return min(score, 100);
}
  Future<bool> updateUser(Map<String, dynamic> userData) async {
    final db = await database;
    final rowsUpdated = await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [userData['id']],
    );
    return rowsUpdated > 0;
  }

  Future<bool> deleteUser(int userId) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return rowsDeleted > 0;
  }

  // User Capabilities
  Future<bool> updateUserCapabilities({
    required int userId,
    bool? isDeaf,
    bool? isBlind,
    bool? isWheelchairBound,
    bool? canAssistDeaf,
    bool? canAssistBlind,
    bool? canAssistWheelchair,
  }) async {
    final db = await database;
    final data = <String, dynamic>{};
    
    if (isDeaf != null) data['isDeaf'] = isDeaf ? 1 : 0;
    if (isBlind != null) data['isBlind'] = isBlind ? 1 : 0;
    if (isWheelchairBound != null) data['isWheelchairBound'] = isWheelchairBound ? 1 : 0;
    if (canAssistDeaf != null) data['canAssistDeaf'] = canAssistDeaf ? 1 : 0;
    if (canAssistBlind != null) data['canAssistBlind'] = canAssistBlind ? 1 : 0;
    if (canAssistWheelchair != null) data['canAssistWheelchair'] = canAssistWheelchair ? 1 : 0;
    
    await db.update(
      'users',
      data,
      where: 'id = ?',
      whereArgs: [userId],
    );
    return true;
  }

  Future<bool> updateUserHelperStatus({
    required int userId,
    required bool isHelper,
  }) async {
    final db = await database;
    await db.update(
      'users',
      {'isHelper': isHelper ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return true;
  }
// Add to DatabaseHelper class
Future<bool> updateUserLocation({
  required int userId,
  required double latitude,
  required double longitude,
  required String postalCode,
}) async {
  final db = await database;
  await db.update(
    'users',
    {
      'latitude': latitude,
      'longitude': longitude,
      'postalCode': postalCode,
    },
    where: 'id = ?',
    whereArgs: [userId],
  );
  return true;
}
  // Helper Search Methods
  Future<List<Map<String, dynamic>>> getHelpersForPostalCode(
    String postalCode, {
    int? userId,
    bool? canAssistDeaf,
    bool? canAssistBlind,
    bool? canAssistWheelchair,
  }) async {
    final db = await database;
    final where = <String>['isHelper = 1', 'postalCode LIKE ?'];
    final whereArgs = <dynamic>['$postalCode%'];
    
    if (userId != null) {
      where.add('id != ?');
      whereArgs.add(userId);
    }
    
    if (canAssistDeaf != null) {
      where.add('canAssistDeaf = ?');
      whereArgs.add(canAssistDeaf ? 1 : 0);
    }
    
    if (canAssistBlind != null) {
      where.add('canAssistBlind = ?');
      whereArgs.add(canAssistBlind ? 1 : 0);
    }
    
    if (canAssistWheelchair != null) {
      where.add('canAssistWheelchair = ?');
      whereArgs.add(canAssistWheelchair ? 1 : 0);
    }
    
    return await db.query(
      'users',
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> getNearbyHelpers({
  required String postalCode,
  required int userId,
  required bool needsDeafAssistance,
  required bool needsBlindAssistance,
  required bool needsWheelchairAssistance,
}) async {
  final db = await database;
  
  // First get the requester's location
  final requesterLocation = await DistanceCalculator.getLocationDetails(postalCode);
  
  // Raw SQL query with distance calculation using Haversine formula
  final query = '''
    SELECT users.*, 
      (ABS(latitude - ?) + ABS(longitude - ?)) AS distance
    FROM users
    WHERE isHelper = 1
      AND id != ?
      ${needsDeafAssistance ? 'AND canAssistDeaf = 1' : ''}
      ${needsBlindAssistance ? 'AND canAssistBlind = 1' : ''}
      ${needsWheelchairAssistance ? 'AND canAssistWheelchair = 1' : ''}
    ORDER BY distance ASC
  ''';

  return await db.rawQuery(query, [
    requesterLocation['latitude'],
    requesterLocation['longitude'],
    userId,
  ]);
}
  Future<List<Map<String, dynamic>>> getHelpersForDeaf(String postalCode, {int? userId}) async {
    return await getHelpersForPostalCode(
      postalCode,
      userId: userId,
      canAssistDeaf: true,
    );
  }

  Future<List<Map<String, dynamic>>> getHelpersForBlind(String postalCode, {int? userId}) async {
    return await getHelpersForPostalCode(
      postalCode,
      userId: userId,
      canAssistBlind: true,
    );
  }

  Future<List<Map<String, dynamic>>> getHelpersForWheelchair(String postalCode, {int? userId}) async {
    return await getHelpersForPostalCode(
      postalCode,
      userId: userId,
      canAssistWheelchair: true,
    );
  }

 Future<List<Map<String, dynamic>>> getNearbyRequests({
  required String postalCode,
  required int userId,
  bool? canAssistDeaf,
  bool? canAssistBlind,
  bool? canAssistWheelchair,
}) async {
  final db = await database;
  final requesterLocation = await DistanceCalculator.getLocationDetails(postalCode);
  
  final query = '''
    SELECT users.*,
       (ABS(latitude - ?) + ABS(longitude - ?)) AS distance
    FROM users
    WHERE id != ?
      ${canAssistDeaf == true ? 'AND isDeaf = 1' : ''}
      ${canAssistBlind == true ? 'AND isBlind = 1' : ''}
      ${canAssistWheelchair == true ? 'AND isWheelchairBound = 1' : ''}
    ORDER BY distance ASC
  ''';

  return await db.rawQuery(query, [
    requesterLocation['latitude'],
    requesterLocation['longitude'],
    userId,
  ]);
}
  Future<List<Map<String, dynamic>>> getRequestsForPostalCode(
    String postalCode, {
    int? userId,
    bool? needsDeafAssistance,
    bool? needsBlindAssistance,
    bool? needsWheelchairAssistance,
  }) async {
    final db = await database;
    final where = <String>['postalCode LIKE ?'];
    final whereArgs = <dynamic>['$postalCode%'];
    
    if (userId != null) {
      where.add('(helperId != ? AND requesterId != ?)');
      whereArgs.addAll([userId, userId]);
    }
    
    if (needsDeafAssistance != null) {
      where.add('service LIKE ?');
      whereArgs.add('%Deaf%');
    }
    
    if (needsBlindAssistance != null) {
      where.add('service LIKE ?');
      whereArgs.add('%Blind%');
    }
    
    if (needsWheelchairAssistance != null) {
      where.add('service LIKE ?');
      whereArgs.add('%Wheelchair%');
    }
    
    return await db.query(
      'requests',
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> getUsersNeedingDeafAssistance(String postalCode, {int? userId}) async {
    final db = await database;
    final where = <String>['isDeaf = 1', 'postalCode LIKE ?'];
    final whereArgs = <dynamic>['$postalCode%'];
    
    if (userId != null) {
      where.add('id != ?');
      whereArgs.add(userId);
    }
    
    return await db.query(
      'users',
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> getUsersNeedingBlindAssistance(String postalCode, {int? userId}) async {
    final db = await database;
    final where = <String>['isBlind = 1', 'postalCode LIKE ?'];
    final whereArgs = <dynamic>['$postalCode%'];
    
    if (userId != null) {
      where.add('id != ?');
      whereArgs.add(userId);
    }
    
    return await db.query(
      'users',
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> getUsersNeedingWheelchairAssistance(String postalCode, {int? userId}) async {
    final db = await database;
    final where = <String>['isWheelchairBound = 1', 'postalCode LIKE ?'];
    final whereArgs = <dynamic>['$postalCode%'];
    
    if (userId != null) {
      where.add('id != ?');
      whereArgs.add(userId);
    }
    
    return await db.query(
      'users',
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  // Add new method to get requests by type
Future<List<Map<String, dynamic>>> getRequestsByType({
  required String requestType,
  String? postalCode,
  bool? needsDeafAssistance,
  bool? needsBlindAssistance,
  bool? needsWheelchairAssistance,
}) async {
  final db = await database;
  final where = <String>['requestType = ?'];
  final whereArgs = <dynamic>[requestType];

  if (postalCode != null) {
    where.add('postalCode LIKE ?');
    whereArgs.add('$postalCode%');
  }

  if (needsDeafAssistance != null) {
    where.add('service LIKE ?');
    whereArgs.add('%Deaf%');
  }

  if (needsBlindAssistance != null) {
    where.add('service LIKE ?');
    whereArgs.add('%Blind%');
  }

  if (needsWheelchairAssistance != null) {
    where.add('service LIKE ?');
    whereArgs.add('%Wheelchair%');
  }

  return await db.query(
    'requests',
    where: where.join(' AND '),
    whereArgs: whereArgs,
  );
}

// Update insertRequest method
Future<bool> insertRequest({
  required String service,
  required String date,
  required String time,
  required String location,
  required String requestType,
  int? helperId,
  int? requesterId,
}) async {
  final db = await database;
  await db.insert(
    'requests',
    {
      'service': service,
      'date': date,
      'time': time,
      'location': location,
      'requestType': requestType,
      'helperId': helperId,
      'requesterId': requesterId,
    },
  );
  return true;
}

// Add method to accept scheduled request
Future<bool> acceptScheduledRequest(int requestId, int helperId) async {
  final db = await database;
  final rowsUpdated = await db.update(
    'requests',
    {
      'helperId': helperId,
      'status': 'accepted',
      'acceptedAt': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [requestId],
  );
  return rowsUpdated > 0;
}

  Future<List<Map<String, dynamic>>> getRequestsForUser(int userId) async {
    final db = await database;
    return await db.query(
      'requests',
      where: 'helperId = ? OR requesterId = ?',
      whereArgs: [userId, userId],
    );
  }

  Future<bool> updateRequestStatus(int requestId, String status) async {
    final db = await database;
    final rowsUpdated = await db.update(
      'requests',
      {'status': status},
      where: 'id = ?',
      whereArgs: [requestId],
    );
    return rowsUpdated > 0;
  }

  Future<bool> deleteRequest(int requestId) async {
    final db = await database;
    final rowsDeleted = await db.delete(
      'requests',
      where: 'id = ?',
      whereArgs: [requestId],
    );
    return rowsDeleted > 0;
  }

  // Message Operations
  Future<bool> sendMessage({
    required int senderId,
    required int receiverId,
    required String text,
  }) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
      },
    );
    return true;
  }

  Future<List<Map<String, dynamic>>> getMessagesBetweenUsers(int userId1, int userId2) async {
    final db = await database;
    return await db.query(
      'messages',
      where: '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
      orderBy: 'timestamp ASC',
    );
  }

  // Additional Utility Methods
  Future<int> getUserCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  Future<bool> emailExists(String email) async {
  final db = await database;
  final users = await db.query(
    'users',
    where: 'email = ?',
    whereArgs: [email],
    limit: 1,
  );
  return users.isNotEmpty;
}

  Future<int> getRequestCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM requests');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
    await db.delete('requests');
    await db.delete('messages');
  }

  getPendingRequestsForUser(int userId) {}
}

