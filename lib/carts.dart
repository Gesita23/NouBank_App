
//THIS IS A DEMO//

import 'package:flutter/material.dart';

const Color primarypurple = Color.fromARGB(255, 13, 71, 161);
const Color secondarypurple = Color.fromARGB(255, 21, 101, 192);

class CartsPage extends StatelessWidget {
  const CartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qr Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: primarypurple,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon:const Icon (Icons.arrow_back,color:Colors.white),
        ),
      ),
      body:const Center(
        child:Text(
          'Cardds',
          style:TextStyle(fontSize:36,fontWeight:FontWeight.bold)
        ),
      ),
    );
  }
}