import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter PB Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PocketBase pb = PocketBase('https://20fe-120-188-84-163.ap.ngrok.io');
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool obscureText = true;
  bool isLoading = false;
  bool isError = false;
  LocalStorage storage = LocalStorage('auth');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: storage.ready,
        builder: (context, snapshot) {
          var data = storage.getItem('auth');
          if (snapshot.connectionState == ConnectionState.done && data != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Welcome, ${data["name"]}"),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });

                      pb.authStore.clear();
                      await storage.clear();
                      setState(() {
                        isLoading = false;
                      });
                    },
                    child: const Text("Log Out"),
                  ),
                ],
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.done && !isLoading) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CustomTextField(
                    hintText: "Email",
                    controller: _emailController,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CustomTextField(
                    hintText: "Password",
                    controller: _passwordController,
                    obscureText: obscureText,
                    ending: GestureDetector(
                        onTap: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                        child: Icon(obscureText ? Icons.visibility : Icons.visibility_off)),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      isError = false;
                      isLoading = true;
                    });

                    try {
                      await pb.collection('users').authWithPassword(_emailController.text, _passwordController.text);
                    } catch (error) {
                      isError = true;
                      log(error.toString());
                    } finally {
                      if (pb.authStore.isValid) {
                        storage.setItem('auth', pb.authStore.model);
                        pb.authStore.save(pb.authStore.token, pb.authStore.model);
                      }
                      setState(() {
                        isLoading = false;
                      });
                    }

                    setState(() {});
                  },
                  child: const Text("Sign In"),
                ),
                const SizedBox(
                  height: 30,
                ),
                if (isError)
                  const Text(
                    "Login Failed",
                    style: TextStyle(color: Colors.red),
                  )
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, this.hintText, this.controller, this.obscureText = false, this.ending});
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? ending;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(border: InputBorder.none, hintText: hintText),
            ),
          ),
          if (ending != null) ending!
        ],
      ),
    );
  }
}
