import 'package:careplusapp/home.dart';
import 'package:careplusapp/product_category.dart';
import 'package:careplusapp/profile.dart';
import 'package:flutter/material.dart';
import 'chat_with_doctor.dart';
import 'order_history.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _FooterItem(
                imagePath: 'asset/image/home.png',
                label: 'Home',
                //route: '/home',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Home()),
                  );
                },
                width: 30,
                height: 30,
              ),
              _FooterItem(
                imagePath: 'asset/image/drug.png',
                label: 'Product',
                //route: '/product_category',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ProductCategory()),
                  );
                },
                width: 30,
                height: 30,
              ),
              _FooterItem(
                imagePath: 'asset/image/messenger.png',
                label: 'Message',

//                 route: '/chat_with_doctor',
//                 width: 26,
//                 height: 26,

                //route: '/home',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ChatWithDoctor()),
                  );
                },
                width: 30,
                height: 30,

              ),
              Column(
                children: [
                  _FooterItem(
                    imagePath: 'asset/image/order_history.png',
                    label: 'Order History',
                    width: 30,
                    height: 30,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => OrderHistory()),
                      );
                    },
                  ),
                ],
              ),

              _FooterItem(
                imagePath: 'asset/image/user.png',
                label: 'Account',
                //route: '/profile',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Profile()),
                  );
                },
                width: 30,
                height: 30,
              ),
            ],
          )
        ),
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final String imagePath;
  final String label;
  //final String route;
  final double width;
  final double height;
  final VoidCallback? onTap;


  const _FooterItem({
    required this.imagePath,
    required this.label,
    //required this.route,
    this.width = 24.0,
    this.height = 24.0,
    this.onTap,

  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        // onTap: () {
        //   Navigator.pushReplacementNamed(context, route);
        // },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: const Color(0xFF6B4518), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
