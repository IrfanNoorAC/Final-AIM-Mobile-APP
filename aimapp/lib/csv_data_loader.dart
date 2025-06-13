import 'dart:async';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:aimapp/database_helper.dart';
import 'package:aimapp/distance_calculator.dart';

class CSVDataLoader {
  static Future<void> loadCSVData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    
    try {
      final csvData = await rootBundle.loadString('assets/data.csv');
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
      
      // Skip header row
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final postalCode = row[1]?.toString() ?? '000000';
        
        try {
          // Get location details for the postal code
          final location = await DistanceCalculator.getLocationDetails(postalCode);
          
          await db.insert(
            'users',
            {
              'username': row[0]?.toString() ?? 'User $i',
              'postalCode': postalCode,
              'sex': row[2]?.toString() ?? 'Unknown',
              'age': _parseAge(row[3]?.toString() ?? ''),
              'height': double.tryParse(row[7]?.toString() ?? '') ?? 0,
              'weight': double.tryParse(row[8]?.toString() ?? '') ?? 0,
              'bmi': double.tryParse(row[9]?.toString() ?? '') ?? 0,
              'isDeaf': (row[4]?.toString() == 'Yes') ? 1 : 0,
              'isBlind': (row[5]?.toString() == 'Yes') ? 1 : 0,
              'isWheelchairBound': (row[6]?.toString() == 'Yes') ? 1 : 0,
              'canAssistDeaf': (row[10]?.toString() == 'Yes') ? 1 : 0,
              'canAssistBlind': (row[11]?.toString() == 'Yes') ? 1 : 0,
              'canAssistWheelchair': (row[12]?.toString() == 'Yes') ? 1 : 0,
              'isHelper': ((row[10]?.toString() == 'Yes') ||
                          (row[11]?.toString() == 'Yes') ||
                          (row[12]?.toString() == 'Yes')) ? 1 : 0,
              'latitude': location['latitude'],
              'longitude': location['longitude'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (e) {
          print('Error processing user ${row[0]}: $e');
        }
      }
    } catch (e) {
      print('Error loading CSV data: $e');
    }
  }

  static int _parseAge(String ageCategory) {
    try {
      final range = ageCategory.replaceAll('Age ', '').replaceAll(' or older', '').split(' to ');
      if (range.length == 2) {
        return (int.parse(range[0]) + int.parse(range[1])) ~/ 2;
      }
      return int.tryParse(range[0]) ?? 30;
    } catch (e) {
      return 30;
    }
  }
}



