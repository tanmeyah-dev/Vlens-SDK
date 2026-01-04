import 'package:flutter/material.dart';
import '../services/loan_service.dart';

/// Loan application conditions and instructions screen.
///
/// This screen displays all conditions and requirements for loan application
/// and allows users to agree to terms before proceeding.
class LoanConditionsScreen extends StatefulWidget {
  final LoanService? loanService;
  final VoidCallback? onStartApplication;

  const LoanConditionsScreen({
    super.key,
    this.loanService,
    this.onStartApplication,
  });

  @override
  State<LoanConditionsScreen> createState() => _LoanConditionsScreenState();
}

class _LoanConditionsScreenState extends State<LoanConditionsScreen> {
  bool _agreedToTerms = false;
  bool _hasExistingProject = false;

  bool get _canStartApplication => _agreedToTerms && _hasExistingProject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Conditions List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildConditionItem(
                      icon: Icons.flag,
                      text: 'أن يكون طالب التمويل مصري الجنسية',
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildConditionItem(
                      icon: Icons.calendar_today,
                      text: 'ان يكون طالب التمويل بين ٢١ عاماً و ٦٥ عاماً',
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildConditionItem(
                      icon: Icons.badge,
                      text: 'بطاقة رقم قومي سارية',
                      iconColor: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildConditionItem(
                      icon: Icons.receipt,
                      text: 'إيصال مرافق',
                      iconColor: Colors.purple,
                    ),
                    const SizedBox(height: 24),

                    // Agreement Checkbox
                    _buildCheckboxItem(
                      value: _agreedToTerms,
                      text: 'لقد قرأت ووافقت على جميع الشروط',
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Project Condition
                    _buildConditionItem(
                      icon: Icons.store,
                      text:
                          'ان يكون طالب التمويل لديه مشروع قائم منذ أكثر من ٦ أشهر',
                      iconColor: Colors.red,
                    ),
                    const SizedBox(height: 16),

                    // Project Checkbox
                    _buildCheckboxItem(
                      value: _hasExistingProject,
                      text: 'نعم لدي مشروع قائم منذ ٦ أشهر',
                      onChanged: (value) {
                        setState(() {
                          _hasExistingProject = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Start Application Button
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'شروط وارشادات طلب التمويل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.red[700],
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 16),
          Checkbox(
            value: value,
            onChanged: onChanged,
            shape: const CircleBorder(),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canStartApplication ? _handleStartApplication : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _canStartApplication ? Colors.red[700] : Colors.grey[300],
          foregroundColor:
              _canStartApplication ? Colors.white : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'بدأ طلب تمويل',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  void _handleStartApplication() {
    if (widget.onStartApplication != null) {
      widget.onStartApplication!();
    } else {
      // Default behavior - you can customize this
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Loan Application')),
            body: const Center(
              child: Text('Loan Application Form - To be implemented'),
            ),
          ),
        ),
      );
    }
  }
}
