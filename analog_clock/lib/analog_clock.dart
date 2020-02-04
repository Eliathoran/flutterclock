// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';
import 'package:analog_clock/image_engine.dart';
import 'package:analog_clock/weather.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;
import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  var _prevTemperature = 0.0;
  var _prevCondition = '';
  Timer _timer;

  Map<int,Image> _images2 = new Map<int,Image>();

  ImageChangerEngine imageEngine;

  @override
  void initState() {
    weatherType = WeatherType.sun;
    super.initState();
    widget.model.addListener(_updateModel);

    // Set the initial values.
    _updateTime();
    _updateModel();
    _updatePreviousModel();
    _loadImages();
  }

  var weatherIcon = Icons.wb_sunny;

  _loadImages(){
    _images2[1] = Image(fit: BoxFit.cover, image: AssetImage("assets/1.png",));
    _images2[2] = Image(fit: BoxFit.cover, image: AssetImage("assets/2.png",));
    _images2[3] = Image(fit: BoxFit.cover, image: AssetImage("assets/3.png",));
    _images2[4] = Image(fit: BoxFit.cover, image: AssetImage("assets/4.png",));
    _images2[5] = Image(fit: BoxFit.cover, image: AssetImage("assets/5.png",));
    _images2[6] = Image(fit: BoxFit.cover, image: AssetImage("assets/6.png",));
    _images2[7] = Image(fit: BoxFit.cover, image: AssetImage("assets/7.png",));
    _images2[8] = Image(fit: BoxFit.cover, image: AssetImage("assets/8.png",));
    _images2[9] = Image(fit: BoxFit.cover, image: AssetImage("assets/9.png",));
    _images2[10] = Image(fit: BoxFit.cover, image: AssetImage("assets/10.png",));

    imageEngine = new ImageChangerEngine(images: _images2);
    imageEngine.addListener(_updateState);
  }

  _updateState(){
    setState(() {

    });
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    imageEngine.removeListener(_updateState);
    super.dispose();
  }

  void _updatePreviousModel(){
    _prevTemperature =  double.tryParse(_temperature.substring(0,_temperature.length-2)) ?? 0;
    _prevCondition = _condition;
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  void _animateBackground(String condition, String prevCondition) {
    switch(_condition){
      case 'cloudy':
        setState(() {
          weatherIcon = FontAwesomeIcons.cloudSun;
          weatherType = WeatherType.cloud;
          imageEngine.nextImageIndex = 4;
        });
        break;
      case 'foggy':
        setState(() {
          weatherIcon = Icons.cloud;
          weatherType = WeatherType.fog;
          imageEngine.nextImageIndex = 5;
        });
        break;
      case 'rainy':
        setState(() {
          weatherIcon = FontAwesomeIcons.cloudRain;
          weatherType = WeatherType.rain;
          imageEngine.nextImageIndex = 1;
        });
        break;
      case 'snowy':
        setState(() {
          weatherIcon = FontAwesomeIcons.snowflake;
          weatherType = WeatherType.snow;
          imageEngine.nextImageIndex = 4;
        });
        break;
        break;
      case 'thunderstorm':
        setState(() {
          weatherIcon = FontAwesomeIcons.bolt;
          weatherType = WeatherType.thunder;
          imageEngine.nextImageIndex = 1;
        });
        break;
      case 'windy':
        setState(() {
          weatherIcon = FontAwesomeIcons.wind;
          weatherType = WeatherType.windy;
          imageEngine.nextImageIndex = 4;
        });
        break;
      case 'sunny':
        setState(() {
          weatherIcon = Icons.wb_sunny;
          weatherType = WeatherType.sun;
          imageEngine.nextImageIndex = 3;
        });
        break;
      default:
    }
    imageEngine.cycleImages();
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFFE3DAC9),
            // Minute hand.
            highlightColor: Color(0xFF56070C),
            // Second hand.
            accentColor: Color(0xFF333333),
            backgroundColor: Color(0xFFD2E3FC),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFF333333),
            highlightColor: Color(0xFF56070C),
            accentColor: Color(0xFFE3DAC9),
            backgroundColor: Color(0xFF3C4043),
          );

    // Condition option
    _animateBackground(_condition, _prevCondition);

    // Temperature option
    final temperatureType = _temperature.substring(_temperature.length-1);
    var temperatureValue = double.tryParse(_temperature.substring(0,_temperature.length-2)) ?? 0;

    if (temperatureType == 'F'){
      temperatureValue = (temperatureValue - 32.0) * 5.0 / 9.0;
    }

    final time = DateFormat.Hms().format(DateTime.now());

    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: customTheme.primaryColor),
      child: Container(
        width: 86,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8.0,),
                  child: Icon(weatherIcon, color: Color(0xFFE3DAC9), size: 20),
                ),
                Text(_temperature, style: TextStyle(color: Color(0xFFE3DAC9), fontSize: 14),),
              ],
            ),
            //Text(_location),
          ],
        ),
      ),
    );

    _updatePreviousModel();

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        color: customTheme.backgroundColor,
        child: Stack(
          children: [
            Weather(weatherType, time),
            imageEngine == null ? Container() :
            Container(
              width: 840,
              child: imageEngine.nextImage,
            ),
            imageEngine == null ? Container() : Container(
              width: 840,
              child: imageEngine.currentImage,
            ),
            Positioned(
              top: 43,
              right: -10,
              child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)
                    ..rotateY(0.65)..rotateZ(-0.1)..rotateX(-0.1),
                  child: _clockWidget(customTheme)),
            ),
            Positioned(
              left: 94,
              bottom: 104.5,
              child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)
                    ..rotateY(5.4)..rotateZ(-0.045),
                  child: weatherInfo),
            ),
            Positioned(
              right: 65,
              bottom: 80,
              child: Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)
                    ..rotateY(-5.5)..rotateZ(0.074),
                  child: Text("Being happy in " + _location)),
            ),
          ],
        ),
      ),
    );
  }

  WeatherType weatherType;

  Widget _clockWidget(customTheme){
    return Container(
      height: 225,
      width: 225,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Transform.translate(
            offset: Offset(2,2),
            child: DrawnHand(
              color: Colors.black45.withAlpha(70),
              thickness: 2,
              size: 0.5,
              angleRadians: _now.second * radiansPerTick,
            ),
          ),
          Transform.translate(
            offset: Offset(2,2),
            child: DrawnHand(
              color: Colors.black45.withAlpha(70),
              thickness: 4,
              size: 0.45,
              angleRadians: _now.minute * radiansPerTick,
            ),
          ),
          Transform.translate(
            offset: Offset(2,2),
            child: DrawnHand(
              color: Colors.black45.withAlpha(70),
              thickness: 4,
              size: 0.4,
              angleRadians: _now.hour * radiansPerHour +
                  (_now.minute / 60) * radiansPerHour,
            ),
          ),
          Positioned(
              top: 50,
              child: Text("12")),
          Positioned(
              right: 53,
              child: Text("3")),
          Positioned(
              bottom: 50,
              child: Text("6")),
          Positioned(
              left: 55,
              child: Text("9")),
          Container(
            width: 80.0,
            height: 80.0,
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.black,
                offset: Offset(1,0.1),
                blurRadius: 4.0,
                spreadRadius: 2.0,
              ),],
              border: Border.all(color:Colors.black45, width: 2.0,),
            ),),
          Container(
            width: 80.0,
            height: 80.0,
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: weatherType == WeatherType.sun ? customTheme.primaryColor :
                customTheme.primaryColor.withAlpha(180) ,
                blurRadius: 2.0,
                spreadRadius: 2.0,
              ),],
              border: Border.all(color:Colors.black45, width: 2.0,),
            ),),
          Container(
            width: 60.0,
            height: 60.0,
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.black45,
                blurRadius: 2.0,
                spreadRadius: 2.0,
              ),],
              border: Border.all(color:Colors.black45, width: 2.0,),
            ),),
          Container(
            width: 10.0,
            height: 10.0,
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.black45,
                blurRadius: 2.0,
                spreadRadius: 2.0,
              ),],
              border: Border.all(color:Colors.black45, width: 2.0,),
            ),),
          Transform.translate(
            offset: Offset(1,1),
            child: DrawnHand(
              color: Colors.black45.withAlpha(70),
              thickness: 2,
              size: 0.5,
              angleRadians: _now.second * radiansPerTick,
            ),
          ),
          Transform.translate(
            offset: Offset(1,1),
            child: DrawnHand(
              color: Colors.black45.withAlpha(70),
              thickness: 4,
              size: 0.45,
              angleRadians: _now.minute * radiansPerTick,
            ),
          ),
          Transform.translate(
            offset: Offset(1,1),
            child: DrawnHand(
              color: Colors.black45.withAlpha(70),
              thickness: 4,
              size: 0.4,
              angleRadians: _now.hour * radiansPerHour +
                  (_now.minute / 60) * radiansPerHour,
            ),
          ),
          DrawnHand(
            color: customTheme.accentColor,
            thickness: 2,
            size: 0.5,
            angleRadians: _now.second * radiansPerTick,
          ),
          DrawnHand(
            color: customTheme.highlightColor,
            thickness: 4,
            size: 0.45,
            angleRadians: _now.minute * radiansPerTick,
          ),
          DrawnHand(
            color: weatherType == WeatherType.sun ? customTheme.primaryColor :
    customTheme.primaryColor.withAlpha(180),
            thickness: 4,
            size: 0.4,
            angleRadians: _now.hour * radiansPerHour +
                (_now.minute / 60) * radiansPerHour,
          ),
        ],
      ),
    );
  }
}
