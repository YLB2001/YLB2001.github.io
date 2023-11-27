List<String> _results = [];
Map<String, dynamic> RSSIReport = {
  "time": "",
  "username": "Yanlin Bai",
  "userID": "123",
  "parkingMapID": "1",
  "BLEBeacons": []
};
DateFormat format = DateFormat('dd MMMM yyyy hh:mm:ss a');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Timer.periodic(Duration(seconds: 1), (Timer t) => postData());
  runApp(MyApp());
}

Future<void> postData() async {
  Map<dynamic, dynamic> _local = RSSIReport.deepcopy();

  try {
    const Map<String, String> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    // DateTime now = DateTime.now();
    //var url = Uri.parse(
    //    'https://2a0t2aefbb.execute-api.us-east-2.amazonaws.com/beta');
    var url = Uri.parse('http://172.20.10.7:5001/update_rssi_data');
    int nowMicroseconds = DateTime.now().microsecondsSinceEpoch;
    // Filter the list to keep items within the last second
    _local['BLEBeacons'] = _local['BLEBeacons'].where((item) {
      // Parse the item
      //print(item);
      var jsonItem = json.decode(item);
      // Get the scanTime as microseconds since the epoch
      //print(jsonItem['scanTime'].runtimeType);

      int itemScanTimeMicroseconds = jsonItem['scanTime'];
      //print(jsonItem['scanTime']);
      // Calculate the time difference in seconds
      int timeDifferenceSeconds =
          (nowMicroseconds - itemScanTimeMicroseconds) ~/ 1000000;
      // Keep if the scanTime is within the last second
      return timeDifferenceSeconds < 1;
    }).toList();
    print(_local);
    if (_local['BLEBeacons'].length == 0) {
      return;
    }
    var response = await http.post(url, body: json.encode(_local));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e, stacktrace) {
    print('Exception: ' + e.toString());
    print('Stacktrace: ' + stacktrace.toString());
  }
}
    beaconEventsController.stream.listen(
        (data) {
          if (data.isNotEmpty && isRunning) {
            setState(() {
              _beaconResult = data;
              //_results.clear();
              var parsedJson = json.decode(_beaconResult);
              String newItemUuid = parsedJson["uuid"];
              //parsedJson["scanTime"] = "1234";
              int index = RSSIReport["BLEBeacons"].indexWhere(
                  (item) => json.decode(item)['UUID'] == newItemUuid);
              //print("index:$index");
              Map<String, dynamic> beaconData = {
                "UUID": parsedJson['uuid'],
                "RSSI": parsedJson['rssi'],
                "scanTime": DateTime.now().microsecondsSinceEpoch
              };
              if (index != -1) {
                // Update the existing item if the new item is more recent
                RSSIReport["BLEBeacons"][index] = json.encode(beaconData);
              } else {
                RSSIReport["BLEBeacons"].add(json.encode(beaconData));
              }
              //print(RSSIReport);
              //print('Name: ${parsedJson['uuid']}');
              _nrMessagesReceived++;
            });

            if (!_isInForeground) {
              _showNotification("Beacons DataReceived: " + data);
            }

            //print("Beacons DataReceived: " + data);
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });