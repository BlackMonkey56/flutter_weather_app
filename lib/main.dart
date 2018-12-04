import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_weather_app/Model/weather_model.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:flutter/services.dart';

Future<WeatherModel> getWeather(String lat, String lang) async{
  final response = await http.get('https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lang&appid=c9edd2391e6003880ee605b01c874b45&units=metric');

  if(response.statusCode == 200) {
    var result = json.decode(response.body);
    var model = WeatherModel.fromJson(result);

    return model;
  }else{
    throw Exception('Failed to load Weather Information...');
  }
}

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, double> currentLocation = new Map();
  StreamSubscription<Map<String, double>> locationSubscription;

  Location location = new Location();
  String error;


  @override
  void initState() {
    super.initState();
    //Default value
    currentLocation['latitude'] = 0.0;
    currentLocation['logitude'] = 0.0;

    initPlatformState();

    locationSubscription = location.onLocationChanged().listen((Map<String, double> result){
      setState(() {
        currentLocation = result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //This codes is to fetch API, convert to data model and display name of place on screen
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(title: Text('WEATHER APP'),),
        body: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: Center(
            child: FutureBuilder<WeatherModel>(
              future: getWeather(currentLocation['latitude'].toString(), currentLocation['longitude'].toString()),
              builder: (context, snapshot){
                if(snapshot.hasData){
                  WeatherModel model = snapshot.data;
                  //Format date
                  var fm = new DateFormat('HH:mm dd EEE MM yyyy');
                  var fm_hour = new DateFormat.Hm();
                  
                  return Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Weather in ${model.name}', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),

                    //Create Row with Image And Temperature
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                      Image.network('https://openweathermap.org/img/w/${model.weather[0].icon}.png'),
                      Text('${model.main.temp}°C',
                        style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),),
                    ],),//Row

                    Text('${fm.format(new DateTime.fromMillisecondsSinceEpoch((model.dt*1000), isUtc: false))}',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),

                    Text('Wind(Speed/Deg) : ${model.wind.speed}/${model.wind.deg}',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),

                    Text('Pressure : ${model.main.pressure}hpa',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),

                    Text('humidity : ${model.main.humidity}',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),

                    Text('Sunrise : ${fm_hour.format(new DateTime.fromMillisecondsSinceEpoch((model.sys.sunrise*1000), isUtc: false))}',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),

                    Text('Sunset : ${fm_hour.format(new DateTime.fromMillisecondsSinceEpoch((model.sys.sunset*1000), isUtc: false))}',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),

                    Text('GeoCode : [${model.coord.lat}/${model.coord.lon}]',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
                  ],);//Widget //Column
                }
                else if(snapshot.hasError){
                  return Text('${snapshot.error}', style: TextStyle(fontSize: 30.0, color: Colors.red),);
                }

                return CircularProgressIndicator(); //Default show loading
              },
            ),//FutureBuilder
          ),//Center
        ),//Container
      ),//Scaffold
    );//MaterialApp
  }

  void initPlatformState() async {
    Map<String, double> my_location;
    try{
      my_location = await location.getLocation();
      error = '';
    }on PlatformException catch(e){
      if(e.code == 'PERMISSION_DENIED'){
        error = 'Permission Denied';
      }else if(e.code == 'PERMISSION_DENIED_NEVER_ASK'){
        error = 'Permission Denied - Please ask the user to enable it from app settings';
      }
      my_location = null;
    }

    setState(() {
      currentLocation = my_location;
    });
  }
}