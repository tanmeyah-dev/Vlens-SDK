import 'package:flutter/material.dart';
import 'package:tan_sdk/tan_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAN SDK',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TanSDKPage(),
    );
  }
}

class TanSDKPage extends StatefulWidget {
  const TanSDKPage({super.key});

  @override
  State<TanSDKPage> createState() => _TanSDKPageState();
}

class _TanSDKPageState extends State<TanSDKPage> {
  late SDKService _sdkService;
  late LoanService _loanService;

  @override
  void initState() {
    super.initState();
    // Initialize SDK
    _sdkService = SDKService(
      config: const SDKConfig(
        debug: true,
        timeout: 30,
        baseUrl: 'https://api.tan_sdk.com', // Set your API base URL
      ),
    );
    _sdkService.initialize();

    // Initialize Loan Service
    _loanService = LoanService(
      config: const SDKConfig(
        debug: true,
        timeout: 30,
        baseUrl: 'https://api.tan_sdk.com', // Set your API base URL
      ),
    );
    _loanService.initialize();
  }

  @override
  void dispose() {
    _sdkService.dispose();
    _loanService.dispose();
    super.dispose();
  }

  void _openLoanConditionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoanConditionsScreen(
          loanService: _loanService,
          onStartApplication: () {
            // Handle start application logic here
            _handleStartLoanApplication();
          },
        ),
      ),
    );
  }

  void _handleStartLoanApplication() {
    // Create loan application
    final application = LoanApplication(
      userId: 'user123',
      nationalId: '12345678901234',
      age: 30,
      hasExistingProject: true,
      projectMonths: 12,
    );

    _loanService.createLoanApplication(application).then((createdApp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan application created: ${createdApp.id}'),
        ),
      );
      Navigator.of(context).pop(); // Go back
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TAN SDK'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SDK Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Initialized: ${_sdkService.isInitialized}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Version: ${SDKConstants.version}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openLoanConditionsScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Loan Conditions Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
