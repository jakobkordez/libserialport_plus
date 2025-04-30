import 'package:flutter/material.dart';

import 'package:libserialport_plus/libserialport_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<SerialPortInfo>? infos;

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Packages')),
        body: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    final ports = SerialPort.getAvailablePorts();
                    infos = ports.map((p) {
                      final port = SerialPort(p);
                      final info = port.getInfo();
                      port.dispose();
                      return info;
                    }).toList();
                  });
                },
                child: infos == null
                    ? const Text('Fetch available ports')
                    : const Text('Refresh available ports'),
              ),
            ),
            spacerSmall,
            if (infos?.isEmpty ?? false)
              const Text('No ports available', style: TextStyle(fontSize: 18))
            else if (infos?.isNotEmpty ?? false) ...[
              const Text('Available ports:', style: TextStyle(fontSize: 18)),
              for (final info in infos!) ...[
                spacerSmall,
                Text(info.toString()),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
