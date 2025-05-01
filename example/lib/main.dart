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
  List<String>? ports;
  List<String>? infos;
  List<SerialPortConfig?>? configs;

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('libserialport_plus')),
        body: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    ports = SerialPort.getAvailablePorts();
                    configs = List.generate(ports!.length, (_) => null);
                    infos = ports!.map((p) {
                      try {
                        final port = SerialPort(p);
                        final info = port.getInfo();
                        port.dispose();
                        return info.toString();
                      } on SerialPortException catch (e, s) {
                        debugPrint(s.toString());
                        return '$p: $e';
                      }
                    }).toList();
                  });
                },
                child: ports == null
                    ? const Text('Fetch available ports')
                    : const Text('Refresh available ports'),
              ),
            ),
            spacerSmall,
            if (ports?.isEmpty ?? false)
              const Text('No ports available', style: TextStyle(fontSize: 18))
            else if (ports?.isNotEmpty ?? false) ...[
              const Text('Available ports:', style: TextStyle(fontSize: 18)),
              for (int i = 0; i < infos!.length; ++i) ...[
                spacerSmall,
                if (i != 0) Divider(),
                spacerSmall,
                Text(infos![i].toString()),
                if (configs![i] != null)
                  Text(configs![i].toString())
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        final port = SerialPort(ports![i]);
                        port.open();
                        setState(() {
                          configs![i] = port.getConfig();
                        });
                        port.close();
                        port.dispose();
                      },
                      child: const Text('Get config'),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
