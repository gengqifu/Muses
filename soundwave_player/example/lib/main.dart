import 'package:flutter/material.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _player = SoundwavePlayer();
  String _status = 'Idle';

  Future<void> _init() async {
    try {
      await _player.init(const SoundwaveConfig(sampleRate: 48000, bufferSize: 2048, channels: 2));
      setState(() => _status = 'Initialized');
    } catch (e) {
      setState(() => _status = 'Init failed: $e');
    }
  }

  Future<void> _load() async {
    try {
      await _player.load('file://sample');
      setState(() => _status = 'Load called (placeholder)');
    } catch (e) {
      setState(() => _status = 'Load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _init, child: const Text('Init player')),
              ElevatedButton(onPressed: _load, child: const Text('Load sample (noop)')),
            ],
          ),
        ),
      ),
    );
  }
}
