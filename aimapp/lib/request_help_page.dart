
import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';
import 'package:aimapp/select_datetime_page.dart';

class RequestHelpPage extends StatefulWidget {
  final int userId;

  const RequestHelpPage({required this.userId, Key? key}) : super(key: key);

  @override
  _RequestHelpPageState createState() => _RequestHelpPageState();
}

class _RequestHelpPageState extends State<RequestHelpPage> {
  late Future<Map<String, dynamic>> _userData;
  String? _selectedService;
  List<String> _availableServices = [];
  final TextEditingController _detailsController = TextEditingController();
  // Default to immediate
  String _requestType = 'immediate'; 

  @override
  void initState() {
    super.initState();
    _userData = DatabaseHelper().getUser(widget.userId).then((user) {
      if (user != null) {
        if (user['isDeaf'] == 1) _availableServices.add('Communication Assistance');
        if (user['isBlind'] == 1) _availableServices.add('Navigation Assistance');
        if (user['isWheelchairBound'] == 1) _availableServices.add('Mobility Assistance');
        
        if (_availableServices.isNotEmpty) {
          _selectedService = _availableServices[0];
        }
      }
      return user ?? {};
    });
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Help')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final user = snapshot.data!;
          final isDeaf = user['isDeaf'] == 1;
          final isBlind = user['isBlind'] == 1;
          final isWheelchairBound = user['isWheelchairBound'] == 1;
          
          if (!isDeaf && !isBlind && !isWheelchairBound) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You haven\'t set any assistance needs'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/settings',
                      arguments: {'userId': widget.userId},
                    ),
                    child: const Text('Update Needs'),
                  ),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select the type of assistance you need:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Request type selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Type:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'immediate',
                              groupValue: _requestType,
                              onChanged: (value) {
                                setState(() {
                                  _requestType = value!;
                                });
                              },
                            ),
                            const Text('Immediate (Find helper now)'),
                          ],
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'scheduled',
                              groupValue: _requestType,
                              onChanged: (value) {
                                setState(() {
                                  _requestType = value!;
                                });
                              },
                            ),
                            const Text('Scheduled (Post for helpers)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Service selection dropdown
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(
                    labelText: 'Service Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableServices.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedService = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a service' : null,
                ),
                
                const SizedBox(height: 20),
                
                // Details text field
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Specific Request Details',
                    hintText: 'e.g., Communication Assistance: help with groceries',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide details about your request';
                    }
                    return null;
                  },
                ),
                
                const Spacer(),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedService == null ? null : () {
                      // Combine service type with details
                      final fullService = '${_selectedService!}: ${_detailsController.text}';
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectDateTimePage(
                            service: fullService,
                            isRequestingHelp: true,
                            userId: widget.userId,
                            requestType: _requestType,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

