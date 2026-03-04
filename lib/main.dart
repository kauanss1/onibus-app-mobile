import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import da memória

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, home: RastreadorCompleto()));
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'rastreio_onibus',
    'Serviço de Rastreio',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'rastreio_onibus',
      initialNotificationTitle: 'Ônibus Motorista',
      initialNotificationContent: 'GPS Ativado',
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await http.post(
        Uri.parse('https://onibus.onrender.com/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lat": pos.latitude,
          "lon": pos.longitude,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Ônibus Motorista - Em Rota",
          content: "Sinal: ${DateTime.now().hour}:${DateTime.now().minute}",
        );
      }
    } catch (e) {
      debugPrint("Erro: $e");
    }
  });
}

class RastreadorCompleto extends StatefulWidget {
  const RastreadorCompleto({super.key});
  @override
  State<RastreadorCompleto> createState() => _RastreadorCompletoState();
}

class _RastreadorCompletoState extends State<RastreadorCompleto> {
  bool _rastreando = false;
  String _placa = "Selecionar Placa";
  final List<String> _listaPlacas = ["BUS-001", "BUS-002", "URBANO-X"];

  @override
  void initState() {
    super.initState();
    _carregarEstado(); // Tenta lembrar o que estava fazendo ao abrir o app
  }

  // FUNÇÃO PARA SALVAR O ESTADO
  void _salvarEstado(bool status, String placa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rastreando', status);
    await prefs.setString('placa', placa);
  }

  // FUNÇÃO PARA CARREGAR O ESTADO
  void _carregarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    setState(() {
      // Só mostra como "rastreando" se o serviço real estiver rodando
      _rastreando = isRunning;
      _placa = prefs.getString('placa') ?? "Selecionar Placa";
    });
  }

  void _alternar() async {
    final service = FlutterBackgroundService();
    bool running = await service.isRunning();

    if (running) {
      service.invoke("stopService");
      _salvarEstado(false, _placa);
      setState(() => _rastreando = false);
    } else {
      if (_placa == "Selecionar Placa") return;
      LocationPermission perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        service.startService();
        _salvarEstado(true, _placa);
        setState(() => _rastreando = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Ônibus Motorista"),
          centerTitle: true,
          backgroundColor: Colors.blue[900]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // ÔNIBUS FICOU MAIOR (Size 180)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child:
                      Icon(Icons.directions_bus, size: 180, color: Colors.blue),
                ),
                Icon(Icons.wifi,
                    size: 60, color: _rastreando ? Colors.green : Colors.grey),
              ],
            ),
            const SizedBox(height: 40),
            DropdownButton<String>(
              hint: Text(_placa,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              items: _listaPlacas
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                setState(() => _placa = v!);
                if (_rastreando) _salvarEstado(true, v!);
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _alternar,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _rastreando ? Colors.red : Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 20)),
              child: Text(
                  _rastreando ? "DESLIGAR RASTREIO" : "INICIAR RASTREIO",
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
