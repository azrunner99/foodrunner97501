import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nps_provider.dart';
import '../services/data_export_service.dart';
import '../models/nps_score_feedback.dart';

/// Widget for exporting NPS data and analytics
class DataExportWidget extends StatefulWidget {
  const DataExportWidget({super.key});

  @override
  State<DataExportWidget> createState() => _DataExportWidgetState();
}

class _DataExportWidgetState extends State<DataExportWidget> {
  bool _isExporting = false;
  String? _lastExportMessage;

  @override
  Widget build(BuildContext context) {
    return Consumer<NPSProvider>(
      builder: (context, npsProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (_lastExportMessage != null) ...[
                  _buildStatusMessage(),
                  const SizedBox(height: 16),
                ],
                _buildExportOptions(npsProvider),
                if (_isExporting) ...[
                  const SizedBox(height: 16),
                  _buildLoadingIndicator(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.download,
          color: Colors.blue.shade600,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Export',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Export NPS data and analytics to CSV files',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lastExportMessage!,
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _lastExportMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions(NPSProvider npsProvider) {
    final hasData = npsProvider.servers.isNotEmpty;
    
    return Column(
      children: [
        _buildExportTile(
          icon: Icons.feedback,
          title: 'Feedback Data',
          subtitle: 'Export all feedback responses with server details',
          enabled: hasData,
          onTap: () => _exportFeedbackData(npsProvider),
        ),
        const SizedBox(height: 8),
        _buildExportTile(
          icon: Icons.analytics,
          title: 'Server Analytics',
          subtitle: 'Export server performance summary and NPS scores',
          enabled: hasData,
          onTap: () => _exportServerAnalytics(npsProvider),
        ),
        const SizedBox(height: 8),
        _buildExportTile(
          icon: Icons.assessment,
          title: 'Comprehensive Report',
          subtitle: 'Export detailed analytics report with insights',
          enabled: hasData,
          onTap: () => _exportComprehensiveReport(npsProvider),
        ),
        const SizedBox(height: 8),
        _buildExportTile(
          icon: Icons.timeline,
          title: 'Time Series Data',
          subtitle: 'Export daily trends and historical data',
          enabled: hasData,
          onTap: () => _exportTimeSeriesData(npsProvider),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildExportTile(
          icon: Icons.archive,
          title: 'Complete Dataset',
          subtitle: 'Export all data types in a single download',
          enabled: hasData,
          primary: true,
          onTap: () => _exportCompleteDataset(npsProvider),
        ),
      ],
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled 
            ? (primary ? Colors.blue.shade100 : Colors.grey.shade100)
            : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled 
            ? (primary ? Colors.blue.shade600 : Colors.grey.shade600)
            : Colors.grey.shade400,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: primary ? FontWeight.bold : FontWeight.w500,
          color: enabled ? null : Colors.grey.shade400,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      trailing: enabled
        ? Icon(
            Icons.download,
            color: primary ? Colors.blue.shade600 : Colors.grey.shade400,
          )
        : Icon(
            Icons.block,
            color: Colors.grey.shade400,
          ),
      onTap: enabled && !_isExporting ? onTap : null,
      enabled: enabled && !_isExporting,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: primary && enabled ? Colors.blue.shade50 : null,
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            'Preparing export...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFeedbackData(NPSProvider npsProvider) async {
    await _performExport(
      'Feedback Data',
      () async {
        final feedback = _generateSampleFeedback(); // Using sample data for now
        final csvContent = await DataExportService.exportFeedbackToCSV(
          feedback,
          npsProvider.servers,
        );
        await DataExportService.shareCSVFile(
          csvContent,
          'nps_feedback_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
      },
    );
  }

  Future<void> _exportServerAnalytics(NPSProvider npsProvider) async {
    await _performExport(
      'Server Analytics',
      () async {
        final feedback = _generateSampleFeedback(); // Using sample data for now
        final csvContent = await DataExportService.exportServerAnalyticsToCSV(
          npsProvider.servers,
          feedback,
        );
        await DataExportService.shareCSVFile(
          csvContent,
          'nps_server_analytics_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
      },
    );
  }

  Future<void> _exportComprehensiveReport(NPSProvider npsProvider) async {
    await _performExport(
      'Comprehensive Report',
      () async {
        final feedback = _generateSampleFeedback(); // Using sample data for now
        final csvContent = await DataExportService.exportComprehensiveAnalyticsToCSV(
          npsProvider.servers,
          feedback,
        );
        await DataExportService.shareCSVFile(
          csvContent,
          'nps_comprehensive_report_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
      },
    );
  }

  Future<void> _exportTimeSeriesData(NPSProvider npsProvider) async {
    await _performExport(
      'Time Series Data',
      () async {
        final feedback = _generateSampleFeedback(); // Using sample data for now
        final csvContent = await DataExportService.exportTimeSeriesDataToCSV(feedback);
        await DataExportService.shareCSVFile(
          csvContent,
          'nps_time_series_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
      },
    );
  }

  Future<void> _exportCompleteDataset(NPSProvider npsProvider) async {
    await _performExport(
      'Complete Dataset',
      () async {
        final feedback = _generateSampleFeedback(); // Using sample data for now
        await DataExportService.exportCompleteDataset(
          npsProvider.servers,
          feedback,
        );
      },
    );
  }

  Future<void> _performExport(String exportType, Future<void> Function() exportFunction) async {
    setState(() {
      _isExporting = true;
      _lastExportMessage = null;
    });

    try {
      await exportFunction();
      setState(() {
        _lastExportMessage = '$exportType exported successfully!';
      });
    } catch (e) {
      setState(() {
        _lastExportMessage = 'Failed to export $exportType: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  // Generate sample feedback data for demonstration
  List<NPSScoreFeedback> _generateSampleFeedback() {
    final List<NPSScoreFeedback> sampleData = [];
    final now = DateTime.now();
    
    // Generate sample feedback for the last 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final numResponses = (i % 3) + 1; // 1-3 responses per day
      
      for (int j = 0; j < numResponses; j++) {
        sampleData.add(NPSScoreFeedback(
          id: (i * 10) + j,
          serverId: (j % 3) + 1, // Distribute across servers
          score: 5 + (i % 6), // Scores from 5-10
          comment: 'Sample feedback for day $i, response $j',
          submissionDate: date,
          createdAt: date,
        ));
      }
    }
    
    return sampleData;
  }
}