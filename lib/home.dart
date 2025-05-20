import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _MyAppState();
}

class _MyAppState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFC1BFA9),
        body: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 20.0),
                  child: GestureDetector(
                    onTap: () {

                      setState(() {});
                    },
                    child: Image.asset(
                      'asset/image/weblogo.png',  // Make sure this path matches your asset folder
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 200.0),
                  child: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        print("Tapped");
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Image.asset(
                        'asset/image/user.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 20.0),
                  child: Image.asset(
                    'asset/image/logout.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            Text(
              'Yours Health, Yours Way!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B4518),
                fontFamily: 'Engagement',  // Make sure your font is declared correctly in pubspec.yaml
                fontSize: 30,
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 25.0, left: 20.0),
                  child: Text(
                    'Pharmacy List',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',  // Make sure your font is declared correctly in pubspec.yaml
                      fontSize: 30,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 32.0, left: 120.0),
                  child: Text(
                    'view more',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0XFF797979),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',  // Make sure your font is declared correctly in pubspec.yaml
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
    );
  }
}
