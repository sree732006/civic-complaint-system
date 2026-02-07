import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/token_storage.dart';

class MyComplaints extends StatefulWidget {
  const MyComplaints({super.key});

  @override
  State<MyComplaints> createState() => _MyComplaintsState();
}

class _MyComplaintsState extends State<MyComplaints> {
  bool loading = true;
  List<dynamic> complaints = [];

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConstants.baseUrl}/api/citizen/complaints");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            complaints = json.decode(response.body);
            loading = false;
          });
        }
      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "My History",
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : complaints.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: complaints.length,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemBuilder: (context, index) {
                    final c = complaints[index];
                    return _buildComplaintCard(c);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Submissions Yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          Text(
            "Issues you report will be listed here\nneatly for your tracking.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(dynamic c) {
    final status = c['status'] ?? 'UNKNOWN';
    final category = c['category'] ?? 'General';
    final severity = c['severity'] ?? 'Low';
    final imageUrl = c['image_url'] ?? '';
    final createdAt = c['created_at'] != null 
        ? DateTime.parse(c['created_at']).toLocal() 
        : DateTime.now();
    
    final street = c['street'] ?? '';
    final area = c['area'] ?? '';
    final city = c['city'] ?? 'Rajapalayam';
    final ward = c['ward'] ?? '';

    Color statusColor;
    switch(status.toUpperCase()) {
      case "RAISED": statusColor = const Color(0xFFFF9800); break;
      case "RESOLVED": 
      case "COMPLETED": statusColor = const Color(0xFF43A047); break;
      case "IN_PROGRESS": statusColor = const Color(0xFF1976D2); break;
      default: statusColor = const Color(0xFF64748B);
    }
    final rating = c['rating'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            if (imageUrl.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    imageUrl.startsWith('http') ? imageUrl : "${ApiConstants.baseUrl}$imageUrl",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _statusBadge(status, statusColor),
                  ),
                ],
              )
            else
              Container(
                height: 80,
                color: statusColor.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(_getCategoryIcon(category), color: statusColor, size: 28),
                    _statusBadge(status, statusColor),
                  ],
                ),
              ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(severity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(severity),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${street.isNotEmpty ? '$street, ' : ''}$area, $city",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (ward.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Text(
                        "Ward No: $ward",
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w600, 
                          color: const Color(0xFF0D47A1).withOpacity(0.8)
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                      if (status == "COMPLETED")
                        if (rating > 0)
                          Row(
                            children: List.generate(5, (index) => Icon(
                              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: Colors.amber,
                            )),
                          )
                        else
                          TextButton(
                            onPressed: () => _showRatingDialog(c['id']),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF43A047),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Rate Resolution", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showRatingDialog(String complaintId) {
    int selectedRating = 0;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Rate Resolution", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "How satisfied are you with the resolution of this issue?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () => setDialogState(() => selectedRating = index + 1),
                  icon: Icon(
                    index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                )),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  hintText: "Your feedback (optional)",
                  fillColor: Colors.grey[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("NOT NOW", style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0 ? null : () {
                _submitFeedback(complaintId, selectedRating, feedbackController.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SUBMIT"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback(String id, int rating, String text) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/citizen/complaints/$id/feedback"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "rating": rating,
          "feedback_text": text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thank you for your feedback!")),
          );
          fetchComplaints();
        }
      }
    } catch (e) {
      debugPrint("Error submitting feedback: $e");
    }
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pipe breakage': return Icons.broken_image_rounded;
      case 'leakage': return Icons.water_drop_rounded;
      case 'overflow': return Icons.waves_rounded;
      case 'sinkhole': return Icons.warning_rounded; 
      case 'manhole missing': return Icons.dangerous_rounded;
      case 'clogged drain': return Icons.filter_list_off_rounded;
      default: return Icons.report_problem_rounded;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return const Color(0xFFD32F2F);
      case 'medium': return const Color(0xFFF57C00);
      default: return const Color(0xFF388E3C);
    }
  }
}
