import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';
import 'package:aimapp/distance_calculator.dart';

class AvailableHelpersPage extends StatefulWidget {
  final String service;
  final String date;
  final String time;
  final String location;
  final String postalCode;
  final bool isRequestingHelp;
  final int userId;
  final String requestType;
  final String initialTransportMode;

  const AvailableHelpersPage({
    required this.service,
    required this.date,
    required this.time,
    required this.location,
    required this.postalCode,
    required this.isRequestingHelp,
    required this.userId,
    this.initialTransportMode = 'walking',
    required this.requestType,
    Key? key,
  }) : super(key: key);

  @override
  _AvailableHelpersPageState createState() => _AvailableHelpersPageState();
}

class _AvailableHelpersPageState extends State<AvailableHelpersPage> {
  late String _transportMode;
  late Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _transportMode = widget.initialTransportMode;
    _matchesFuture = _getMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRequestingHelp ? 'Available Helpers' : 'Available Requests'),
        actions: [
          IconButton(
            icon: Icon(_getTransportModeIcon()),
            onPressed: () => _showTransportModeDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final matches = snapshot.data ?? [];
          
          if (matches.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildMatchesList(matches);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64),
          const SizedBox(height: 16),
          Text(
            widget.requestType == 'immediate' 
              ? 'No available matches found'
              : 'No pending requests found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('For postal code: ${widget.postalCode}'),
          Text('Transport mode: ${_transportMode.toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _buildMatchesList(List<Map<String, dynamic>> matches) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              child: Text(match['username'][0]),
            ),
            title: Text(match['username']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${match['age']} years old'),
                Text(match['sex']),
                if (widget.requestType == 'scheduled') ...[
                ],
                _buildScoreSection(match),
                Text(match['distanceText'], style: TextStyle(color: Colors.blue)),
                if (match['timeText'] != null && match['timeText'].isNotEmpty)
                  Text('ETA (${_transportMode.toUpperCase()}): ${match['timeText']}', 
                      style: TextStyle(color: Colors.green)),
                _buildCapabilitiesOrNeeds(match),
                Text(
                  'Request Type: ${widget.requestType == 'immediate' ? 'Immediate Help' : 'Scheduled Help'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.requestType == 'immediate' ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => _navigateToDetails(context, match),
          ),
        );
      },
    );
  }

  Widget _buildScoreSection(Map<String, dynamic> match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isRequestingHelp ? 'Match Score:' : 'Request Score:',
          style: TextStyle(
            color: _getScoreColor(match['score']),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (match['score'] ?? 0) / 100,
          backgroundColor: Colors.grey[200],
          color: _getScoreColor(match['score']),
          minHeight: 4,
        ),
        Text(
          '${match['score']?.toStringAsFixed(1) ?? 'N/A'}',
          style: TextStyle(
            color: _getScoreColor(match['score']),
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getMatches() async {
    List<Map<String, dynamic>> rawMatches;
    
    if (widget.isRequestingHelp) {
      rawMatches = await DatabaseHelper().getRankedHelpers(
        requesterId: widget.userId,
        postalCode: widget.postalCode,
        needsDeafAssistance: widget.service.contains('Deaf') || widget.service.contains('Communication'),
        needsBlindAssistance: widget.service.contains('Blind') || widget.service.contains('Navigation'),
        needsWheelchairAssistance: widget.service.contains('Wheelchair') || widget.service.contains('Mobility'),
      );
    } else {
      if (widget.requestType == 'immediate') {
        rawMatches = await DatabaseHelper().getRankedRequesters(
          helperId: widget.userId,
          postalCode: widget.postalCode,
          canAssistDeaf: widget.service.contains('Deaf'),
          canAssistBlind: widget.service.contains('Blind'),
          canAssistWheelchair: widget.service.contains('Wheelchair'),
        );
      } else {
        rawMatches = await DatabaseHelper().getPendingScheduledRequests(
          helperId: widget.userId,
          postalCode: widget.postalCode,
          canAssistDeaf: widget.service.contains('Deaf'),
          canAssistBlind: widget.service.contains('Blind'),
          canAssistWheelchair: widget.service.contains('Wheelchair'),
        );
      }
    }

    return _enhanceMatchesWithTransportData(rawMatches);
  }

  Future<List<Map<String, dynamic>>> _enhanceMatchesWithTransportData(
      List<Map<String, dynamic>> matches) async {
    final enhancedMatches = <Map<String, dynamic>>[];
    
    for (final match in matches) {
      try {
        final distanceInfo = await DistanceCalculator.getDistanceAndTime(
          widget.postalCode,
          match['postalCode'],
          transportMode: _transportMode,
        );
        
        enhancedMatches.add({
          ...match,
          'distanceText': distanceInfo['distanceText'],
          'timeText': distanceInfo['timeText'],
        });
      } catch (e) {
        enhancedMatches.add({
          ...match,
          'distanceText': 'Distance unavailable',
          'timeText': null,
        });
      }
    }
    
    return enhancedMatches;
  }

  IconData _getTransportModeIcon() {
    switch (_transportMode) {
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      case 'bus':
        return Icons.directions_bus;
      case 'driving':
        return Icons.directions_car;
      default:
        return Icons.directions;
    }
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCapabilitiesOrNeeds(Map<String, dynamic> match) {
    if (widget.isRequestingHelp) {
      final capabilities = <String>[];
      if (match['canAssistDeaf'] == 1) capabilities.add('Deaf Assistance');
      if (match['canAssistBlind'] == 1) capabilities.add('Blind Assistance');
      if (match['canAssistWheelchair'] == 1) capabilities.add('Wheelchair Assistance');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Can Assist:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...capabilities.map((capability) => Text('• $capability')),
        ],
      );
    } else {
      final needs = <String>[];
      if (match['isDeaf'] == 1) needs.add('Deaf Assistance');
      if (match['isBlind'] == 1) needs.add('Blind Assistance');
      if (match['isWheelchairBound'] == 1) needs.add('Wheelchair Assistance');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Needs:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...needs.map((need) => Text('• $need')),
        ],
      );
    }
  }

  void _navigateToDetails(BuildContext context, Map<String, dynamic> match) {
    Navigator.pushNamed(
      context,
      '/helper-details',
      arguments: {
        'helper': match,
        'service': widget.service,
        'date': widget.date,
        'time': widget.time,
        'location': widget.location,
        'isRequestingHelp': widget.isRequestingHelp,
        'userId': widget.userId,
        'transportMode': _transportMode,
        'requestType': widget.requestType,
      },
    );
  }

  void _showTransportModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Transport Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.directions_walk),
              title: const Text('Walking'),
              onTap: () => _updateTransportMode(context, 'walking'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_bike),
              title: const Text('Cycling'),
              onTap: () => _updateTransportMode(context, 'cycling'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text('Bus'),
              onTap: () => _updateTransportMode(context, 'bus'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Driving'),
              onTap: () => _updateTransportMode(context, 'driving'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateTransportMode(BuildContext context, String newMode) {
    Navigator.pop(context);
    setState(() {
      _transportMode = newMode;
      // Refresh matches with new transport mode
      _matchesFuture = _getMatches(); 
    });
  }

}