import 'package:flutter/material.dart';
import 'package:ojt_management_system/pages/certificate_page.dart';
import 'package:ojt_management_system/pages/input_page.dart';
import 'package:ojt_management_system/pages/table_page.dart';
import 'package:ojt_management_system/pages/generate_qr_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedPage = 'home'; // Default page is 'home'
  String? hoveredPage;

  // Update the selected page
  void _onPageSelected(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (Drawer)
          Container(
            width: 135,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 241, 246, 248),
              border: Border(right: BorderSide(color: Colors.white, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  'assets/images/pgp_logo.png',
                  height: 85, // adjust size as needed
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),

                // Home
                GestureDetector(
                  onTap: () {
                    _onPageSelected('home');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'home'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.home,
                          color:
                              selectedPage == 'home'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'home'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'home'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Add Student
                GestureDetector(
                  onTap: () {
                    _onPageSelected('input');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentInputPage(),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'input'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.person_add,
                          color:
                              selectedPage == 'input'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Add Student',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'input'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'input'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // View Students
                GestureDetector(
                  onTap: () {
                    _onPageSelected('table');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TablePage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'table'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.table_chart,
                          color:
                              selectedPage == 'table'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'View Students',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'table'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'table'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Generate QR Code
                GestureDetector(
                  onTap: () {
                    _onPageSelected('qr');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GenerateQrPage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'qr'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.qr_code,
                          color:
                              selectedPage == 'qr'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Generate QR Code',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'qr'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'qr'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Generate Certificate
                GestureDetector(
                  onTap: () {
                    _onPageSelected('certificate');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CertificatePage()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              selectedPage == 'certificate'
                                  ? const Color.fromARGB(255, 193, 211, 228)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 17,
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color:
                              selectedPage == 'certificate'
                                  ? Colors.black
                                  : Colors.black54,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Create Certificate',
                        style: TextStyle(
                          fontWeight:
                              selectedPage == 'certificate'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              selectedPage == 'certificate'
                                  ? Colors.black
                                  : Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Text on the left
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'On-the-Job Training\n Management System',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // Image on the right
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Image(
                            image: AssetImage('assets/images/ojt_logo.png'),
                            width: 450, // Adjust as needed
                            height: 450,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Welcome to OJT Management System!',
                    style: TextStyle(fontSize: 26),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
