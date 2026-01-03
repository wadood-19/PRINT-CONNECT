import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'api_service.dart';

void main() => runApp(const MaterialApp(
  home: HomeScreen(),
  debugShowCheckedModeBanner: false,
));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _otpController = TextEditingController();
  File? _selectedFile;
  bool _isPrinting = false;
  bool _showMainContent = false;

  @override
  void initState() {
    super.initState();
    // Start sequence: Show logo first, then transition to main UI after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showMainContent = true);
    });
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  void _handlePrint() async {
    if (_otpController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP and select a PDF")),
      );
      return;
    }

    // START PRINTING ANIMATION
    setState(() => _isPrinting = true);

    // CALL YOUR API SERVICE
    bool success = await ApiService.sendPrintJob(_otpController.text, _selectedFile!);

    // END PRINTING ANIMATION
    setState(() => _isPrinting = false);
    _showResult(success);
  }

  void _showResult(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ZoomIn(
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(success ? Icons.verified : Icons.error,
                  color: success ? Colors.cyanAccent : Colors.redAccent, size: 70),
              const SizedBox(height: 20),
              Text(success ? "PRINTING STARTED" : "UPLOAD FAILED",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              if (!success)
                const Text("Check connection or OTP", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 20),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE", style: TextStyle(color: Colors.cyanAccent))
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      // AppBar only appears when dashboard is active
      appBar: _showMainContent && !_isPrinting ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: FadeInDown(
          child: Text("PRINT CONNECT",
              style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: 2)
          ),
        ),
      ) : null,
      body: Stack(
        children: [
          // 1. LOGO ANIMATION (Initial Splash)
          if (!_showMainContent)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ZoomIn(
                    duration: const Duration(seconds: 1),
                    child: const Icon(Icons.print, size: 120, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Text("PRINT CONNECT",
                        style: GoogleFonts.oswald(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40, letterSpacing: 4)
                    ),
                  ),
                ],
              ),
            ),

          // 2. MAIN DASHBOARD CONTENT
          if (_showMainContent && !_isPrinting)
            FadeIn(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      controller: _otpController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 32, letterSpacing: 10),
                      decoration: InputDecoration(
                        labelText: "ENTER KIOSK OTP",
                        labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 1),
                        enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white10),
                            borderRadius: BorderRadius.circular(15)
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                            borderRadius: BorderRadius.circular(15)
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildFileCard(),
                    const SizedBox(height: 50),
                    _buildPrintButton(),
                  ],
                ),
              ),
            ),

          // 3. PRINTING ANIMATION (While API is busy)
          if (_isPrinting)
            Center(
              child: FadeIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SpinKitDoubleBounce(color: Colors.cyanAccent, size: 150),
                    const SizedBox(height: 40),
                    Flash(
                      infinite: true,
                      child: Text("UPLOADING TO KIOSK...",
                          style: GoogleFonts.oswald(color: Colors.cyanAccent, fontSize: 24, letterSpacing: 3)
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _selectedFile != null ? Colors.cyanAccent : Colors.transparent),
      ),
      child: ListTile(
        onTap: _pickFile,
        leading: Icon(Icons.picture_as_pdf, color: _selectedFile != null ? Colors.cyanAccent : Colors.redAccent),
        title: Text(_selectedFile == null ? "Select Document" : "PDF Ready", style: const TextStyle(color: Colors.white)),
        subtitle: Text(_selectedFile?.path.split(Platform.pathSeparator).last ?? "Touch to browse files",
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38)),
        trailing: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
      ),
    );
  }

  Widget _buildPrintButton() {
    return BounceInUp(
      child: SizedBox(
        width: double.infinity,
        height: 65,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              elevation: 10,
              shadowColor: Colors.cyanAccent.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
          onPressed: _handlePrint,
          child: const Text("START PRINTING",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ),
    );
  }
}