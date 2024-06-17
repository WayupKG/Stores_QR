import '../colors.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart'; // Для работы с буфером обмена
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Для кодирования и декодирования JSON
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

class ScannedBarcode {
  final String code;
  final DateTime timestamp;

  ScannedBarcode(this.code, this.timestamp);

  Map<String, dynamic> toJson() => {
        'code': code,
        'timestamp': timestamp.toIso8601String(),
      };

  static ScannedBarcode fromJson(Map<String, dynamic> json) => ScannedBarcode(
        json['code'],
        DateTime.parse(json['timestamp']),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String barcode = 'Сканируйте баркод';
  List<ScannedBarcode> scannedBarcodes = [];
  final AssetsAudioPlayer _assetsAudioPlayer =
      AssetsAudioPlayer(); // Создаем экземпляр AssetsAudioPlayer

  @override
  void initState() {
    super.initState();
    _loadScannedBarcodes();
  }

  @override
  void dispose() {
    _assetsAudioPlayer.dispose();
    super.dispose();
  }

  void _playScanSound() {
    try {
      _assetsAudioPlayer.open(
        Audio("assets/sounds/scan_sound.mp3"),
        autoStart: true,
      );
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> _loadScannedBarcodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonStringList = prefs.getStringList('scannedBarcodes') ?? [];
    setState(() {
      scannedBarcodes = jsonStringList
          .map((jsonString) => ScannedBarcode.fromJson(json.decode(jsonString)))
          .toList();
    });
  }

  Future<void> _saveScannedBarcodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonStringList = scannedBarcodes
        .map((scannedBarcode) => json.encode(scannedBarcode.toJson()))
        .toList();
    prefs.setStringList('scannedBarcodes', jsonStringList);
  }

  void deleteBarcode(int index) {
    setState(() {
      scannedBarcodes.removeAt(index);
      _saveScannedBarcodes();
    });
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.success(
        message: 'Успешно удалено!',
        backgroundColor: CustomColors.success,
        textStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      displayDuration: const Duration(milliseconds: 100),
    );
  }

  void deleteAllBarcode() {
    setState(() {
      scannedBarcodes = [];
      _saveScannedBarcodes();
    });
  }

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        if (result.rawContent.isNotEmpty) {
          barcode = result.rawContent;
          scannedBarcodes.add(ScannedBarcode(barcode, DateTime.now()));
          _saveScannedBarcodes();
        }
        _playScanSound();
      });
    } catch (e) {
      setState(() {
        barcode = 'Failed to get barcode: $e';
      });
    }
  }

  void copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showTopSnackBar(
      Overlay.of(context),
      const CustomSnackBar.success(
        message: 'Успешно скопировано!',
        backgroundColor: CustomColors.success,
        textStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      displayDuration: const Duration(milliseconds: 100),
    );
  }

  void shareBarcode(String code) {
    Share.share(code);
  }

  void _delete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Подтверждение'),
          content: const Text('Вы действительно хотите удалить все баркоды?'),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              onPressed: () {
                deleteAllBarcode();
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(CustomColors.danger),
                fixedSize: WidgetStateProperty.all(const Size(130, 40)),
              ),
              child: const Text(
                'Удалить',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.grey),
                  fixedSize: WidgetStateProperty.all(const Size(130, 40)),
                ),
                child: const Text(
                  'Отменить',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stores QR Reader',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _delete(context),
            icon: const Icon(
              FontAwesomeIcons.trash,
              color: Colors.white,
            ),
          )
        ],
        backgroundColor: CustomColors.primary,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              color: CustomColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    barcode,
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              )),
          Expanded(
            child: ListView.builder(
              itemCount: scannedBarcodes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("${index + 1}) ${scannedBarcodes[index].code}"),
                  subtitle: Text(DateFormat('dd.MM.yyyy HH:mm:ss')
                      .format(scannedBarcodes[index].timestamp)),
                  onTap: () {
                    setState(() {
                      barcode = scannedBarcodes[index].code;
                    });
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy,
                            size: 25, color: CustomColors.info),
                        onPressed: () =>
                            copyToClipboard(scannedBarcodes[index].code),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share,
                            size: 25, color: CustomColors.info),
                        onPressed: () =>
                            shareBarcode(scannedBarcodes[index].code),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 25, color: CustomColors.danger),
                        onPressed: () => deleteBarcode(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => shareBarcode(barcode),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      CustomColors.primary,
                    ),
                    padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.share,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: scanBarcode,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      CustomColors.primary,
                    ),
                    overlayColor: WidgetStateProperty.all(
                      CustomColors.primaryDark,
                    ),
                    shadowColor: WidgetStateProperty.all(Colors.red),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 30,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Сканировать',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => copyToClipboard(barcode),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      CustomColors.primary,
                    ),
                    animationDuration: const Duration(milliseconds: 100),
                    padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.copy_all_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
