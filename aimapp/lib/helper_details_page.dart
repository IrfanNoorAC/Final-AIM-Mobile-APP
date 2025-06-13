import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';

class HelperDetailsPage extends StatelessWidget {
  final Map<String, dynamic> helper;
  final String service;
  final String date;
  final String time;
  final String location;
  final bool isRequestingHelp;
  final int userId;
  final String requestType;

  const HelperDetailsPage({
    required this.helper,
    required this.service,
    required this.date,
    required this.time,
    required this.location,
    required this.isRequestingHelp,
    required this.userId,
    required this.requestType,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRequestingHelp ? 'Helper Details' : 'Requester Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              helper['username'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('${helper['age']} years old'),
            Text(helper['sex']),
            
            if (helper['height'] != null && helper['weight'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text('Height: ${helper['height']} cm'),
                  Text('Weight: ${helper['weight']} kg'),
                  if (helper['bmi'] != null)
                    Text('BMI: ${helper['bmi'].toStringAsFixed(1)}'),
                ],
              ),
            
            const SizedBox(height: 20),
            
            if (helper['score'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRequestingHelp ? 'Compatibility Score:' : 'Assistance Score:',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: helper['score'] / 100,
                          backgroundColor: Colors.grey[200],
                          color: _getScoreColor(helper['score']),
                          minHeight: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${helper['score'].toStringAsFixed(1)}/100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(helper['score']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCompatibilityDetails(),
                ],
              ),
            
            const SizedBox(height: 20),
            
            Text('Service: $service', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Date: $date'),
            Text('Time: $time'),
            Text('Location: $location'),
            Text('Type: ${requestType == 'immediate' ? 'Immediate' : 'Scheduled'}'),
            
            const SizedBox(height: 20),
            
            if (!isRequestingHelp) ...[
              Text(
                'Can Assist With:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
              if (helper['canAssistDeaf'] == 1) const Text('• Deaf/Hard of hearing'),
              if (helper['canAssistBlind'] == 1) const Text('• Blind/Visually impaired'),
              if (helper['canAssistWheelchair'] == 1) const Text('• Wheelchair/Mobility challenges'),
              const SizedBox(height: 10),
              
              Text(
                'Requester Needs:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
              if (helper['isDeaf'] == 1) const Text('• Deaf/Hard of hearing'),
              if (helper['isBlind'] == 1) const Text('• Blind/Visually impaired'),
              if (helper['isWheelchairBound'] == 1) const Text('• Wheelchair/Mobility challenges'),
              const SizedBox(height: 10),
            ] else ...[
              Text(
                'Can Assist With:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
              if (helper['canAssistDeaf'] == 1) const Text('• Deaf/Hard of hearing'),
              if (helper['canAssistBlind'] == 1) const Text('• Blind/Visually impaired'),
              if (helper['canAssistWheelchair'] == 1) const Text('• Wheelchair/Mobility challenges'),
              const SizedBox(height: 10),
            ],
            
            if (helper['postalCode'] != null)
              Text('Postal Code: ${helper['postalCode']}'),
            
            const Spacer(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _startChat(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRequestingHelp ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 50),
                  ),
                  child: Text(isRequestingHelp
                      ? requestType == 'immediate' ? 'Request Help' : 'Post Request'
                      : requestType == 'immediate' ? 'Offer Help' : 'Accept Request'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 50),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compatibility Factors:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        if (!isRequestingHelp) ...[
          if (helper['canAssistDeaf'] == 1 && helper['isDeaf'] == 1)
            const Text('✓ Can assist with Deaf needs'),
          if (helper['canAssistBlind'] == 1 && helper['isBlind'] == 1)
            const Text('✓ Can assist with Blind needs'),
          if (helper['canAssistWheelchair'] == 1 && helper['isWheelchairBound'] == 1)
            const Text('✓ Can assist with Wheelchair needs'),
        ] else ...[
          if (helper['canAssistDeaf'] == 1 && helper['isDeaf'] == 1)
            const Text('✓ Matched on Deaf Assistance'),
          if (helper['canAssistBlind'] == 1 && helper['isBlind'] == 1)
            const Text('✓ Matched on Blind Assistance'),
          if (helper['canAssistWheelchair'] == 1 && helper['isWheelchairBound'] == 1)
            const Text('✓ Matched on Wheelchair Assistance'),
        ],
        
        if (helper['height'] != null)
          Text('✓ Height: ${helper['height']} cm'),
        if (helper['bmi'] != null)
          Text('✓ BMI: ${helper['bmi'].toStringAsFixed(1)}'),
        if (helper['distanceText'] != null)
          Text('✓ Distance: ${helper['distanceText']}'),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  void _startChat(BuildContext context) async {
    if (requestType == 'scheduled' && !isRequestingHelp) {
      // For scheduled requests, helper needs to accept first
      final dbHelper = DatabaseHelper();
      
      try {
        // Update the existing request with helperId and status
        await dbHelper.acceptScheduledRequest(helper['requestId'], userId);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'otherUser': helper,
        'service': service,
        'date': date,
        'time': time,
        'location': location,
        'isRequestingHelp': isRequestingHelp,
        'userId': userId,
        'requestType': requestType,
      },
    );
  }
}