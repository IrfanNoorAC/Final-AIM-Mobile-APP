
import 'package:aimapp/database_helper.dart';

class DataService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> getNearbyHelpers({
    required String postalCode,
    bool? canAssistDeaf,
    bool? canAssistBlind,
    bool? canAssistWheelchair,
  }) async {
    final helpers = await _dbHelper.getHelpersForPostalCode(
      postalCode,
      canAssistDeaf: canAssistDeaf,
      canAssistBlind: canAssistBlind,
      canAssistWheelchair: canAssistWheelchair,
    );
    return helpers;
  }

  Future<List<Map<String, dynamic>>> getNearbyRequests({
    required String postalCode,
    bool? needsDeafAssistance,
    bool? needsBlindAssistance,
    bool? needsWheelchairAssistance,
  }) async {
    final requests = await _dbHelper.getRequestsForPostalCode(
      postalCode,
      needsDeafAssistance: needsDeafAssistance,
      needsBlindAssistance: needsBlindAssistance,
      needsWheelchairAssistance: needsWheelchairAssistance,
    );
    return requests;
  }

  Future<bool> createRequest(Map<String, dynamic> requestData) async {
    return await _dbHelper.insertRequest(
      service: requestData['service'],
      date: requestData['date'],
      time: requestData['time'],
      location: requestData['location'],
      helperId: requestData['helperId'],
      requesterId: requestData['requesterId'],
      requestType: requestData['requestType']
    );
  }
}
