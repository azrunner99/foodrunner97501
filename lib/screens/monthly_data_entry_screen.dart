import 'package:flutter/material.dart';
import '../services/database_service.dart';

class MonthlyDataEntryScreen extends StatefulWidget {
  const MonthlyDataEntryScreen({super.key});

  @override
  _MonthlyDataEntryScreenState createState() => _MonthlyDataEntryScreenState();
}

class _MonthlyDataEntryScreenState extends State<MonthlyDataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverIdController = TextEditingController();
  final _monthController = TextEditingController();
  final _npsScoreController = TextEditingController();
  final _feedbackCountController = TextEditingController();

  @override
  void dispose() {
    _serverIdController.dispose();
    _monthController.dispose();
    _npsScoreController.dispose();
    _feedbackCountController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'server_id': int.parse(_serverIdController.text),
        'month': _monthController.text,
        'nps_score': double.parse(_npsScoreController.text),
        'feedback_count': int.parse(_feedbackCountController.text),
      };

      await DatabaseService().insert('monthly_reports', data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Monthly data entry saved successfully!')),
      );

      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Data Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _serverIdController,
                decoration: InputDecoration(labelText: 'Server ID'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid Server ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _monthController,
                decoration: InputDecoration(labelText: 'Month (YYYY-MM)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid month';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _npsScoreController,
                decoration: InputDecoration(labelText: 'NPS Score'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid NPS Score';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _feedbackCountController,
                decoration: InputDecoration(labelText: 'Feedback Count'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid Feedback Count';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
