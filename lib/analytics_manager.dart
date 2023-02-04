import 'dart:convert';
import 'dart:io';

import 'package:analytics/model/event/event.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AnalyticsManager {
  String ip;

  String? _deviceModel;
  String? _analyticsUserId;

  final List<Event> _storedEvents = [];
  late final String _filename = "events_${DateTime.now().toIso8601String()}";

  List<Event> get storedEvents => _storedEvents;

  Future<File> get _storedFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/analytics/$_filename.json");
  }

  Future<Directory> get _storedFilesFolder async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory("${directory.path}/analytics/");
  }

  AnalyticsManager({required this.ip});

  Future<void> initialSetup() async {
    (await _storedFile).create(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    _attachUserIdIfNeeded(prefs);
    _analyticsUserId = prefs.getString(_analyticsUserIdKey);
    _deviceModel = await _getId();
    _sendCachedEvents();
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    final event = Event(name: name, parameters: params == null ? {} : {...params});
    event.parameters["analytics_user_id"] = _analyticsUserId;
    event.parameters["model"] = _deviceModel;
    event.parameters["timestamp"] = DateTime.now().toIso8601String();
    event.parameters["platform"] = Platform.operatingSystem.toString();
    print("EVENT: ${event.name}; PARAMETERS: ${event.parameters}");

    final file = await _storedFile;
    _storedEvents.add(event);
    file.writeAsString(jsonEncode(_storedEvents));
  }

  Future<void> logErrorEvent(Object error, {StackTrace? stackTrace}) async {
    final event = Event(name: "error", parameters: {
      "analytics_user_id": _analyticsUserId,
      "description": error.toString(),
      "model": _deviceModel,
      "timestamp": DateTime.now().toIso8601String(),
      "platform": Platform.operatingSystem.toString()
    });

    print("ERROR. PARAMETERS: ${event.parameters}");
    if (stackTrace != null) {
      event.parameters["stack_trace"] = stackTrace.toString();
    }

    final file = await _storedFile;
    _storedEvents.add(event);
    file.writeAsString(jsonEncode(_storedEvents));
  }

  void _attachUserIdIfNeeded(SharedPreferences prefs) async {
    if (!prefs.containsKey(_analyticsUserIdKey)) {
      prefs.setString(_analyticsUserIdKey, const Uuid().v4());
    }
  }

  Future<void> _sendCachedEvents() async {
    (await _storedFilesFolder).list().forEach((element) async {
      final File file = File(element.path);
      try {
        final content = await file.readAsString();
        final response = await http.post(Uri.parse("http://$ip/analytics/event"), body: content);
        if (response.statusCode == 200) {
          file.delete();
        }
      } catch (error) {
        print(error);
      }
    });
  }
}

Future<String?> _getId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    final iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.name;
  } else if (Platform.isAndroid) {
    final androidDeviceInfo = await deviceInfo.androidInfo;
    return androidDeviceInfo.product;
  }
  return null;
}

String _analyticsUserIdKey = "analyticsUserId";
