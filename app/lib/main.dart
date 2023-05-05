import 'dart:async';
// import 'dart:developer';

// import 'package:beacon/prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'registration.dart';
import 'usercubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

var token = '';
User theUser = User();

Future<void> main() async {
  AuthAPI authAPI = AuthAPI();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var status = prefs.getBool('isLoggedIn') ?? false;
  token = prefs.getString('token') ?? '';
  print("status incoming bro");
  print(status);
  print(token);
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(
    status: status,
  ));
}

var serverAddress = '10.0.2.2:5173';

class MyApp extends StatelessWidget {
  final bool status;

  const MyApp({
    this.status = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User test = User(
      name: "name",
      email: "name@email.com",
      phone: "phone",
      token: "token",
      dateOfBirth: "dateOfBirth",
      blood: "B-",
      docID: "docID",
      address: "address",
      docType: "Passport",
    );

    test.printAll();

    return MaterialApp(
        title: 'Namer App',
        routes: {
          MapsPage.routeName: (context) => const MapsPage(),
          RegisterPage.routeName: (context) => const RegisterPage(),
          Auth.routeName: (context) => Auth(),
        },
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          textTheme: GoogleFonts.nunitoSansTextTheme(),
        ),
        home: kDebugMode
            ? AddDialog(status: status)
            : (status ? MyHomePage() : Auth()),
      );
  }
}

class AddDialog extends StatefulWidget {
  final bool status;
  const AddDialog({required this.status, Key? key}) : super(key: key);

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  final dialogFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    dialogFieldController.text = serverAddress;
    print("status from add dialog");
    print(widget.status);
    return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
        title: Text("[DEBUG] Change Server"),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: dialogFieldController,
            ),
            ElevatedButton(
                onPressed: () {
                  dialogFieldController.text = '10.0.2.2:5173';
                },
                child: Text("Server on emulator PC")),
            ElevatedButton(
                onPressed: () {
                  dialogFieldController.text =
                      'testsite.southeastasia.cloudapp.azure.com:4173';
                },
                child: Text("Online Server")),
            Padding(padding: EdgeInsets.only(bottom: 30)),
            ElevatedButton(
                onPressed: () async {
                  serverAddress = dialogFieldController.text;
                  if (token != '') {
                    AuthAPI authAPI = AuthAPI();
                    print('token here');
                    print(token);
                    var user = await authAPI.getUserw(token);
                    print("user here");
                    print(user.body);
                    theUser = User.fromReqBody(user.body);
                    print(theUser);
                  }
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              (widget.status ? MyHomePage() : Auth())),
                    );
                  }
                },
                child: Text("Confirm")),
          ],
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Position position;
  String _currentAddress = "Waiting for location...";
  AuthAPI authAPI = AuthAPI();
  var _channel;
  bool isPolice = false;
  bool isFire = false;
  bool isMedical = false;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    startTimer();
  }

  _getCurrentLocation() async {
    position = await _determinePosition();
    String temp = await _getAddressFromLatLng();
    print("getcurrent something");
    print(token);
    if (mounted) {
      setState(() {
      _currentAddress = temp;
    });
    }
  }

  Future<String> _getAddressFromLatLng() async {
    double lat = position.latitude;
    double lng = position.longitude;

    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyBKEI1M_LZSWWEa6AMJCorqfSsVXgD79ns');

    final response = await http.get(url);
    print(response.body);
    print(json.decode(response.body)['results'][0]['formatted_address']);

    return await json.decode(response.body)['results'][0]['formatted_address'];
  }

  bool isTimerActive = false;
  int _totcounter = 15;
  int _remcounter = 15;
  double progressFraction = 0.0;
  Timer? timer;
  void startTimer() {
    _remcounter = 15;
    isTimerActive = true;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
        if (_remcounter > 0) {
          _remcounter--;
          progressFraction = (_totcounter - _remcounter) / _totcounter;
        } else {
          timer.cancel();
        }
      });
      }
    });
  }

  void _resetCounter() {
    setState(() {
      _remcounter = 0;
      progressFraction = 100;
      isPolice = isChecked ? isPolice : true;
    });
  }

  void _skipToEmergency(bool police, bool medical, bool fire) {
    print("isPolice: $isPolice");
    print("isFire: $isFire");
    print("isMedical: $isMedical");
    // _channel = WebSocketChannel.connect(Uri.parse(''));
    // _channel.sink.add({'token': token, 'police' : police, 'medical': medical, 'fire': fire});
  }

  void _sendEmergency(bool police, bool medical, bool fire) {
    // _channel = WebSocketChannel.connect(Uri.parse(''));
    // _channel.sink.add({'token' : token, 'police': police, 'medical': medical, 'fire': fire});
  }

  int get counter => _remcounter;
  @override
  Widget build(BuildContext context) {
    AuthAPI authAPI = AuthAPI();
    //var appState = context.watch<MyAppState>();

    return Scaffold(
      //SlidingUpPanel(panel: Center(child: Text("This is the sliding Widget"),),),

      body: Stack(children: [
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Color(0xFFE33D55),
                    ),
                    Flexible(
                      child: TextButton(
                        onPressed: () async {
                          //_getCurrentLocation();

                          // for debugging purposes
                          print("position incoming...");
                          print(position.latitude);
                          print(position.longitude);

                          if (context.mounted) {
                            Navigator.pushNamed(
                              context,
                              MapsPage.routeName,
                              arguments: position,
                            );
                          }
                        },
                        child: Text(
                          _currentAddress,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  (_remcounter > 0)
                      ? Text("")
                      : Text("EMERGENCY SENT",
                          style: TextStyle(
                              color: Color(0xFFE33D55),
                              fontStyle: FontStyle.italic)),
                  Padding(padding: EdgeInsets.all(8.0)), // Add some padding
                  Stack(
                    alignment: Alignment(0, 0),
                    children: [
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progressFraction,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$_remcounter' 's',
                          style: TextStyle(
                              fontSize: 60, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(8.0)), // Add some padding

                  ElevatedButton(
                      onPressed: () {
                        _resetCounter();
                        _skipToEmergency(isPolice, isMedical, isFire);
                      },
                      child: Text('Skip')),
                  //Text(appState.current.asLowerCase),
                ],
              ),
              Padding(padding: EdgeInsets.all(8.0)), // Add some padding

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () {
                      print(isFire);
                      setState(() {
                        isFire = !isFire;
                      });
                      print(isFire);
                    },
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                            checkColor: Colors.white,
                            value: isFire,
                            onChanged: (bool? value) {
                              setState(() {
                                isFire = value!;
                                isChecked = true;
                              });
                            }),
                        Icon(
                          Icons.local_fire_department_outlined,
                          color: Colors.white,
                          size: 50,
                        ),
                        Text(
                          "FIRE",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w100,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    label: SizedBox.shrink(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFDF465B),
                      fixedSize: Size(105, 144),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                      shadowColor: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      print(isMedical);
                      setState(() {
                        isMedical = !isMedical;
                        isChecked = true;
                      });
                      print(isMedical);
                    },
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                            checkColor: Colors.white,
                            value: isMedical,
                            onChanged: (bool? value) {
                              setState(() {
                                isMedical = value!;
                              });
                            }),
                        Icon(
                          Icons.local_hospital_outlined,
                          color: Colors.white,
                          size: 50,
                        ),
                        Text(
                          "HOSPITAL",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    label: SizedBox.shrink(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFDF465B),
                      fixedSize: Size(105, 144),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                      shadowColor: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      print(isPolice);
                      setState(() {
                        isPolice = !isPolice;
                        isChecked = true;
                      });
                      print(isPolice);
                    },
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                            checkColor: Colors.white,
                            value: isPolice,
                            onChanged: (bool? value) {
                              setState(() {
                                isPolice = value!;
                              });
                            }),
                        Icon(
                          Icons.local_police_outlined,
                          color: Colors.white,
                          size: 50,
                        ),
                        Padding(padding: EdgeInsets.only(bottom: 10)),
                        Text(
                          "POLICE",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w100,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    label: SizedBox.shrink(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFDF465B),
                      fixedSize: Size(105, 144),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                      shadowColor: Colors.black,
                    ),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.all(8)),
              SizedBox(),
              ElevatedButton(
                  onPressed: () {
                    _sendEmergency(isPolice, isMedical, isFire);
                  
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const UserSide()),
                    // );
                  },
                  child: Text(
                      'Submit')) //can be made to disappear when skip is pressed?
            ],
          ),
        ),
        SlidingUpPanel(
          minHeight: 100,
          maxHeight: 300,
          panel: Column(children: [
            Text("Name: ${theUser.name}"),
            Text("Phone: ${theUser.phone}"),
            Text("Email: ${theUser.email}"),
            Text("Date of Birth: ${theUser.dateOfBirth}"),
            Text("Blood Group: ${theUser.blood}"),
            Text("Address: ${theUser.address}"),
            Text("Document Type/ID: ${theUser.docType}/${theUser.docID}"),
          ]),
          collapsed: Container(
            decoration: BoxDecoration(
                color: Color(0xffeaeaeb)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          theUser.name!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        theUser.phone!,
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                      ElevatedButton(onPressed: 
                      () async {
                        AuthAPI authAPI = AuthAPI();
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        prefs.remove('token');
                        prefs.remove('isLoggedIn');
                        var res = await authAPI.logout(token);
                        token = '';
                        print(res.body);
                        if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/auth' , (route) => false);
                      }, 
                      child: Text("Logout"))
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/sounds/IMG_0751.JPG'),
                )
              ],
            ),
          ),
        ),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add your onPressed code here!
        },
        label: const Text(
          'LogOut',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(
          Icons.logout_outlined,
          color: Colors.white,
        ),
        backgroundColor: Color(0xFF363F6E),
      ),
    );
  }
}


class UserSide extends StatelessWidget {
  const UserSide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
      ),
      
    );
  }
} 

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  static const routeName = '/maps';

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;

  //final LatLng _center = const LatLng(27.688415, 85.335490);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Position;

    return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green[700],
        ),
        home: Scaffold(
          body: SafeArea(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              markers: {
                Marker(
                  markerId: MarkerId('marker_1'),
                  position: LatLng(
                      args.latitude.toDouble(), args.longitude.toDouble()),
                  draggable: true,
                  onDragEnd: (value) {},
                  infoWindow: InfoWindow(
                    title: 'Marker 1',
                    snippet: 'This is a snippet',
                  ),
                ),
              },
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target:
                    LatLng(args.latitude.toDouble(), args.longitude.toDouble()),
                zoom: 16.0,
              ),
            ),
          ),
        ));
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  print("Position fetched!!!");
  return await Geolocator.getCurrentPosition();
}
