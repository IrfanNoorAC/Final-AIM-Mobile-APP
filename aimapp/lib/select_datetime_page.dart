
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:aimapp/select_location_page.dart';

class SelectDateTimePage extends StatefulWidget {
  final String service;
  final bool isRequestingHelp;
  final int userId;
  final String requestType;

  const SelectDateTimePage({
    required this.service,
    required this.isRequestingHelp,
    required this.userId,
    required this.requestType,
    Key? key,
  }) : super(key: key);

  @override
  _SelectDateTimePageState createState() => _SelectDateTimePageState();
}

class _SelectDateTimePageState extends State<SelectDateTimePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRequestingHelp ? 'Request Help' : 'Offer Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service: ${widget.service}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Type: ${widget.requestType == 'immediate' ? 'Immediate' : 'Scheduled'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // For immediate requests, show current time automatically
              if (widget.requestType == 'immediate')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date: Today'),
                    Text('Time: ${DateFormat('h:mm a').format(DateTime.now())}'),
                    const SizedBox(height: 20),
                  ],
                )
              else
                Column(
                  children: [
                    DateTimeField(
                      controller: _dateController,
                      format: DateFormat('EEEE, MMMM d, yyyy'),
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null ? 'Please select a date' : null,
                      onShowPicker: (context, currentValue) async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: currentValue ?? DateTime.now(),
                        );
                        return date;
                      },
                    ),
                    const SizedBox(height: 20),
                    DateTimeField(
                      controller: _timeController,
                      format: DateFormat('h:mm a'),
                      decoration: const InputDecoration(
                        labelText: 'Select Time',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null ? 'Please select a time' : null,
                      onShowPicker: (context, currentValue) async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        return DateTimeField.convert(time);
                      },
                    ),
                  ],
                ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.requestType == 'immediate' || _formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectLocationPage(
                            service: widget.service,
                            date: widget.requestType == 'immediate' 
                                ? DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())
                                : _dateController.text,
                            time: widget.requestType == 'immediate'
                                ? DateFormat('h:mm a').format(DateTime.now())
                                : _timeController.text,
                            isRequestingHelp: widget.isRequestingHelp,
                            userId: widget.userId,
                            requestType: widget.requestType,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

