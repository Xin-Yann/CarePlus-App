import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController valueController;
  final Function() onChanged;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.valueController,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: const EdgeInsets.all(8.0)
          .copyWith(top: 10.0, left: 20.0, right:20.0),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],  // hint text color
            fontStyle: FontStyle.italic,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: const Color(0xFFFFFFFF),
              width: 2,
            ),
          ),
        ),
        controller: valueController,
        // onChanged: (value) {
        //   onChanged();
        // },
        keyboardType: TextInputType.number,
      ),
    );
  }
}
