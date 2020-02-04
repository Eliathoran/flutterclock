// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui show Image;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spritewidget/spritewidget.dart';

// The image map hold all of our image assets.
ImageMap _images;

// The sprite sheet contains an image and a set of rectangles defining the
// individual sprites.
SpriteSheet _sprites;

enum WeatherType {
  sun,
  rain,
  snow,
  fog,
  cloud,
  thunder,
  windy,
}

class Weather extends StatefulWidget {
  Weather(this.weatherType, this.time, { Key key }) : super(key: key);

  final WeatherType weatherType;
  final time;
  static const String routeName = '/weather';

  @override
  _WeatherState createState() => new _WeatherState();
}

class _WeatherState extends State<Weather> {

  // This method loads all assets that are needed for the demo.
  Future<Null> _loadAssets(AssetBundle bundle) async {
    // Load images using an ImageMap
    _images = new ImageMap(bundle);
    await _images.load(<String>[
      'assets/clouds-0.png',
      'assets/clouds-1.png',
      'assets/ray.png',
      'assets/sun.png',
      'assets/weathersprites.png',
      'assets/wind.png',
    ]);

    // Load the sprite sheet, which contains snowflakes and rain drops.
    String json = await DefaultAssetBundle.of(context).loadString('assets/weathersprites.json');
    _sprites = new SpriteSheet(_images['assets/weathersprites.png'], json);
  }

  @override
  void initState() {
    // Always call super.initState
    super.initState();

    // Get our root asset bundle
    AssetBundle bundle = rootBundle;

    // Load all graphics, then set the state to assetsLoaded and create the
    // WeatherWorld sprite tree
    _loadAssets(bundle).then((_) {
      setState(() {
        assetsLoaded = true;
        weatherWorld = new WeatherWorld();
      });
    });
  }

  bool assetsLoaded = false;

  // The weather world is our sprite tree that handles the weather
  // animations.
  WeatherWorld weatherWorld;

  @override
  Widget build(BuildContext context) {
    // Until assets are loaded we are just displaying a blue screen.
    // If we were to load many more images, we might want to do some
    // loading animation here.
    if (!assetsLoaded) {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text('Weather'),
        ),
        body: new Container(
          decoration: new BoxDecoration(
            color: const Color(0xff4aaafb),
          ),
        ),
      );
    }

    weatherWorld.weatherType = widget.weatherType;
    // All assets are loaded, build the whole app with weather buttons
    // and the WeatherWorld.
    return new Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
        colors: [_kBackgroundColorsTop[widget.weatherType.index],
                _kBackgroundColorsBottom[widget.weatherType.index]]),
            )
          ),
        new SpriteWidget(weatherWorld),
      ],
    );
  }
}



// For the different weathers we are displaying different gradient backgrounds,
// these are the colors for top and bottom.
const List<Color> _kBackgroundColorsTop = const <Color>[
  const Color(0xFF5ebbd5),
  const Color(0xFF0b2734),
  const Color(0xFFcbced7),
  const Color(0xFFcbced7),
  const Color(0xFF5ebbd5),
  const Color(0xFF0b2734),
  const Color(0xFF5ebbd5),
];

const List<Color> _kBackgroundColorsBottom = const <Color>[
  const Color(0xFF4aaafb),
  const Color(0xFF4c5471),
  const Color(0xFFe0e3ec),
  const Color(0xFFcbced7),
  const Color(0xFF5ebbd5),
  const Color(0xFF0b2734),
  const Color(0xFF4aaafb),
];

// The WeatherWorld is our root node for our sprite tree. The size of the tree
// will be scaled to fit into our SpriteWidget container.
class WeatherWorld extends NodeWithSize{
  WeatherWorld() : super(const Size(2048.0, 2048.0)) {

    // Start by adding a background.
    _background = new GradientNode(
      this.size,
      Colors.transparent,
      Colors.transparent,
    );

    addChild(_background);

    // Then three layers of clouds, that will be scrolled in parallax.
    _cloudsSharp = new CloudLayer(
      image: _images['assets/clouds-0.png'],
      rotated: false,
      dark: false,
      loopTime: 20.0
    );
    addChild(_cloudsSharp);

    _cloudsDark = new CloudLayer(
      image: _images['assets/clouds-1.png'],
      rotated: true,
      dark: true,
      loopTime: 40.0
    );
    addChild(_cloudsDark);

    // Add the sun, rain, and snow (which we are going to fade in/out depending
    // on which weather are selected.
    _sun = new Sun();
    _sun.position = const Offset(1024.0, 1024.0);
    _sun.scale = 1.5;
    addChild(_sun);

    _rain = new Rain();
    addChild(_rain);

    _snow = new Snow();
    addChild(_snow);

    _fog = new Fog();
    addChild(_fog);

    _cloud = new Fog();
    addChild(_cloud);

    _thunder = new Thunder(_background);
    addChild(_thunder);

    _windy = new Windy();
    addChild(_windy);
  }

  GradientNode _background;
  CloudLayer _cloudsSharp;
  CloudLayer _cloudsDark;
  Sun _sun;
  Rain _rain;
  Snow _snow;
  Fog _fog;
  Fog _cloud;
  Thunder _thunder;
  Windy _windy;

  WeatherType get weatherType => _weatherType;

  WeatherType _weatherType = WeatherType.sun;

  set weatherType(WeatherType weatherType) {
    if (weatherType == _weatherType)
      return;

    // Handle changes between weather types.
    _weatherType = weatherType;

    // Fade the background
    _background.motions.stopAll();

    // Fade the background from one gradient to another.
    _background.motions.run(new MotionTween<Color>(
      (a) => _background.colorTop = a,
      _background.colorTop,
      _kBackgroundColorsTop[weatherType.index],
      1.0
    ));

    _background.motions.run(new MotionTween<Color>(
      (a) => _background.colorBottom = a,
      _background.colorBottom,
      _kBackgroundColorsBottom[weatherType.index],
      1.0
    ));

    // Activate/deactivate sun, rain, snow, and dark clouds.
    _cloudsSharp.active = weatherType == WeatherType.cloud;
    _cloudsDark.active = weatherType != WeatherType.sun;
    _sun.active = weatherType == WeatherType.sun ||
    weatherType == WeatherType.cloud || weatherType == WeatherType.windy;
    _sun.scale = weatherType == WeatherType.sun ? 1.5 : 0.5;
    _rain.active = weatherType == WeatherType.rain ||
        weatherType == WeatherType.thunder;
    _snow.active = weatherType == WeatherType.snow;
    _thunder.active = weatherType == WeatherType.thunder;
    _windy.active = weatherType == WeatherType.windy;
  }

  @override
  void spriteBoxPerformedLayout() {
    // If the device is rotated or if the size of the SpriteWidget changes we
    // are adjusting the position of the sun.
    _sun.position = spriteBox.visibleArea.topLeft + const Offset(350.0, 180.0);
  }
}

// The GradientNode performs custom drawing to draw a gradient background.
class GradientNode extends NodeWithSize {
  GradientNode(Size size, this.colorTop, this.colorBottom) : super(size);

  Color colorTop;
  Color colorBottom;

  @override
  void paint(Canvas canvas) {
    applyTransformForPivot(canvas);

    Rect rect = Offset.zero & size;
    Paint gradientPaint = new Paint()..shader = new LinearGradient(
      begin: FractionalOffset.topLeft,
      end: FractionalOffset.bottomLeft,
      colors: <Color>[colorTop, colorBottom],
      stops: <double>[0.0, 1.0]
    ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);
  }
}

// Draws and animates a cloud layer using two sprites.
class CloudLayer extends Node {
  CloudLayer({ ui.Image image, bool dark, bool rotated, double loopTime }) {
    // Creates and positions the two cloud sprites.
    _sprites.add(_createSprite(image, dark, rotated));
    _sprites[0].position = const Offset(1024.0, 1024.0);
    addChild(_sprites[0]);

    _sprites.add(_createSprite(image, dark, rotated));
    _sprites[1].position = const Offset(3072.0, 1024.0);
    addChild(_sprites[1]);

    // Animates the clouds across the screen.
    motions.run(new MotionRepeatForever(
      new MotionTween<Offset>(
        (a) => position = a,
        Offset.zero,
        const Offset(-2048.0, 0.0),
        loopTime)
    ));
  }

  List<Sprite> _sprites = <Sprite>[];

  Sprite _createSprite(ui.Image image, bool dark, bool rotated) {
    Sprite sprite = new Sprite.fromImage(image);

    if (rotated)
      sprite.scaleX = -1.0;

    if (dark) {
      sprite.colorOverlay = const Color(0xff000000);
      sprite.opacity = 0.0;
    }

    return sprite;
  }

  set active(bool active) {
    // Toggle visibility of the cloud layer
    double opacity;
    if (active) opacity = 1.0;
    else opacity = 0.0;

    for (Sprite sprite in _sprites) {
      sprite.motions.stopAll();
      sprite.motions.run(new MotionTween<double>(
        (a) => sprite.opacity = a,
        sprite.opacity,
        opacity,
        1.0
      ));
    }
  }
}

const double _kNumSunRays = 50.0;

// Create an animated sun with rays
class Sun extends Node {

  Sun() {
    // Create the sun
    _sun = new Sprite.fromImage(_images['assets/sun.png']);
    _sun.scale = 4.0;
    _sun.transferMode = BlendMode.plus;
    addChild(_sun);

    // Create rays
    _rays = <Ray>[];
    for (int i = 0; i < _kNumSunRays; i += 1) {
      Ray ray = new Ray();
      addChild(ray);
      _rays.add(ray);
    }
  }

  Sprite _sun;
  List<Ray> _rays;

  set active(bool active) {
    // Toggle visibility of the sun

    motions.stopAll();

    double targetOpacity;
    if (!active) targetOpacity = 0.0;
    else targetOpacity = 1.0;

    motions.run(
      new MotionTween<double>(
        (a) => _sun.opacity = a,
        _sun.opacity,
        targetOpacity,
        2.0
      )
    );

    if (active) {
      for (Ray ray in _rays) {
        motions.run(new MotionSequence(<Motion>[
          new MotionDelay(1.5),
          new MotionTween<double>(
            (a) => ray.opacity = a,
            ray.opacity,
            ray.maxOpacity,
            1.5
          )
        ]));
      }
    } else {
      for (Ray ray in _rays) {
        motions.run(new MotionTween<double>(
          (a) => ray.opacity = a,
          ray.opacity,
          0.0,
          0.2
        ));
      }
    }
  }
}

// An animated sun ray
class Ray extends Sprite {
  double _rotationSpeed;
  double maxOpacity;

  Ray() : super.fromImage(_images['assets/ray.png']) {
    pivot = const Offset(0.0, 0.5);
    transferMode = BlendMode.plus;
    rotation = randomDouble() * 360.0;
    maxOpacity = randomDouble() * 0.2;
    opacity = maxOpacity;
    scaleX = 2.5 + randomDouble();
    scaleY = 0.3;
    _rotationSpeed = randomSignedDouble() * 2.0;

    // Scale animation
    double scaleTime = randomSignedDouble() * 2.0 + 4.0;

    motions.run(new MotionRepeatForever(
      new MotionSequence(<Motion>[
        new MotionTween<double>((a) => scaleX = a, scaleX, scaleX * 0.5, scaleTime),
        new MotionTween<double>((a) => scaleX = a, scaleX * 0.5, scaleX, scaleTime)
      ])
    ));
  }

  @override
  void update(double dt) {
    rotation += dt * _rotationSpeed;
  }
}

// Rain layer.
class Rain extends Node {
  Rain() {
    _addParticles(2);
    _addParticles(3);
    _addParticles(4);
    _addParticles(2);
    _addParticles(3);
    _addParticles(4);
  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(double distance) {
    ParticleSystem particles = new ParticleSystem(
      _sprites['raindrop.png'],
      transferMode: BlendMode.srcATop,
      posVar: const Offset(1300.0, 0.0),
      direction: 90.0,
      directionVar: 0.0,
      speed: 1000.0 / distance,
      speedVar: 100.0 / distance,
      startSize: 1.2 / distance,
      startSizeVar: 0.2 / distance,
      endSize: 1.2 / distance,
      endSizeVar: 0.2 / distance,
      life: 1.5 * distance,
      lifeVar: 1.0 * distance
    );
    particles.position = const Offset(1024.0, -200.0);
    particles.rotation = 10.0;
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  set active(bool active) {
    motions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        motions.run(
          new MotionTween<double>(
            (a) => system.opacity = a,
            system.opacity,
            1.0,
            2.0
        ));
      } else {
        motions.run(
          new MotionTween<double>(
            (a) => system.opacity = a,
            system.opacity,
            0.0,
            0.5
        ));
      }
    }
  }
}

// Rain layer.
class Windy extends Node {
  Windy() {
    _addParticles(2);
    _addParticles(3);
    _addParticles(4);
    _addParticles(4);
  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(double distance) {
    ParticleSystem particles = new ParticleSystem(
        Sprite.fromImage(_images['assets/wind.png']).texture,
        transferMode: BlendMode.srcATop,
        posVar: const Offset(1300.0, 0.0),
        direction: -320.0,
        directionVar: 0.0,
        speed: 1000.0 / distance,
        speedVar: 100.0 / distance,
        startSize: 1.2 / distance,
        startSizeVar: 0.2 / distance,
        endSize: 1.2 / distance,
        endSizeVar: 0.2 / distance,
        life: 1.5 * distance,
        lifeVar: 1.0 * distance,
        gravity: Offset(-487.9316,21.333),
      colorSequence: ColorSequence([Colors.brown.withAlpha(170),Colors.brown.shade600.withAlpha(170),Colors.brown.shade200.withAlpha(170)], [0.0,0.5,1.0]),
    );
    particles.position = const Offset(1024.0, 50.0);
    particles.rotation = 10.0;
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  set active(bool active) {
    motions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        motions.run(
            new MotionTween<double>(
                    (a) => system.opacity = a,
                system.opacity,
                1.0,
                2.0
            ));
      } else {
        motions.run(
            new MotionTween<double>(
                    (a) => system.opacity = a,
                system.opacity,
                0.0,
                0.5
            ));
      }
    }
  }
}


// Thunder.
class Thunder extends Node{

  GradientNode _background;
  Thunder(GradientNode background) {
    _background = background;
    _addParticles(1.0);
    _addParticles(1.5);
    _addParticles(2.0);
  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  bool _active = false;
  void _addParticles(double distance) {
    ParticleSystem particles = new ParticleSystem(
        _sprites['flake-0.png'],
        transferMode: BlendMode.srcATop,
        posVar: const Offset(73.0, 40.0),
        direction: 271.0,
        directionVar: 38.32,
        speed: 39.27 / distance,
        speedVar: 50.0 / distance,
        startSize: 1.2 / distance,
        startSizeVar: 0.2 / distance,
        endSize: 1.2 / distance,
        endSizeVar: 0.2 / distance,
        life: 1.5 * distance,
        lifeVar: 1.0 * distance
    );
    particles.position = const Offset(1024.0, -200.0);
    particles.rotation = 10.0;
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  _thunders() async {
    Random rand = Random();
    while(_active){
      await Future.delayed( Duration(seconds : 15 + rand.nextInt(30)));
      // Fade the background from one gradient to another.
      _background.motions.run(new MotionTween<Color>(
              (a) => _background.colorTop = a,
          _background.colorTop,
          _kBackgroundColorsTop[2],
          0.2
      ));

      _background.motions.run(new MotionTween<Color>(
              (a) => _background.colorBottom = a,
          _background.colorBottom,
          _kBackgroundColorsBottom[2],
          0.3
      ));

      await Future.delayed(const Duration(milliseconds : 200));
      // Chance color to previous one

      if (_active) {
        _background.motions.run(new MotionTween<Color>(
                (a) => _background.colorTop = a,
            _background.colorTop,
            _kBackgroundColorsTop[5],
            0.5
        ));

        _background.motions.run(new MotionTween<Color>(
                (a) => _background.colorBottom = a,
            _background.colorBottom,
            _kBackgroundColorsBottom[5],
            0.5
        ));
      }
    }
  }

  set active(bool active) {
    this._active = active;
    motions.stopAll();
    _thunders();
    for (ParticleSystem system in _particles) {
      if (active) {
        motions.run(
            new MotionTween<double>(
                    (a) => system.opacity = a,
                system.opacity,
                1.0,
                2.0
            ));
      } else {
        motions.run(
            new MotionTween<double>(
                    (a) => system.opacity = a,
                system.opacity,
                0.0,
                0.5
            ));
      }
    }
  }
}

// Snow.
class Snow extends Node {
  Snow() {
    _addParticles(_sprites['flake-0.png'], 2.0);
    _addParticles(_sprites['flake-1.png'], 2.0);
    _addParticles(_sprites['flake-2.png'], 2.0);

    _addParticles(_sprites['flake-3.png'], 3);
    _addParticles(_sprites['flake-4.png'], 3);
    _addParticles(_sprites['flake-5.png'], 3);

    _addParticles(_sprites['flake-6.png'], 4);
    _addParticles(_sprites['flake-7.png'], 4);
    _addParticles(_sprites['flake-8.png'], 4);

    _addParticles(_sprites['flake-0.png'], 2.0);
    _addParticles(_sprites['flake-1.png'], 2.0);
    _addParticles(_sprites['flake-2.png'], 2.0);

    _addParticles(_sprites['flake-3.png'], 3);
    _addParticles(_sprites['flake-4.png'], 3);
    _addParticles(_sprites['flake-5.png'], 3);

    _addParticles(_sprites['flake-6.png'], 4);
    _addParticles(_sprites['flake-7.png'], 4);
    _addParticles(_sprites['flake-8.png'], 4);

  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(SpriteTexture texture, double distance) {
    ParticleSystem particles = new ParticleSystem(
      texture,
      transferMode: BlendMode.srcATop,
      posVar: const Offset(1300.0, 0.0),
      direction: 90.0,
      directionVar: 0.0,
      speed: 150.0 / distance,
      speedVar: 50.0 / distance,
      startSize: 1.0 / distance,
      startSizeVar: 0.3 / distance,
      endSize: 1.2 / distance,
      endSizeVar: 0.2 / distance,
      life: 20.0 * distance,
      lifeVar: 10.0 * distance,
      emissionRate: 2.0,
      startRotationVar: 360.0,
      endRotationVar: 360.0,
      radialAccelerationVar: 10.0 / distance,
      tangentialAccelerationVar: 10.0 / distance
    );
    particles.position = const Offset(1024.0, -50.0);
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  set active(bool active) {
    motions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        motions.run(
          new MotionTween<double>((a) => system.opacity = a, system.opacity, 1.0, 2.0
        ));
      } else {
        motions.run(
          new MotionTween<double>((a) => system.opacity = a, system.opacity, 0.0, 0.5
        ));
      }
    }
  }
}

// Fog.
class Fog extends Node {
  Fog();

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(SpriteTexture texture, double distance) {
    ParticleSystem particles = new ParticleSystem(
        texture,
        transferMode: BlendMode.srcATop,
        posVar: const Offset(1300.0, 0.0),
        direction: 90.0,
        directionVar: 0.0,
        speed: 150.0 / distance,
        speedVar: 50.0 / distance,
        startSize: 1.0 / distance,
        startSizeVar: 0.3 / distance,
        endSize: 1.2 / distance,
        endSizeVar: 0.2 / distance,
        life: 20.0 * distance,
        lifeVar: 10.0 * distance,
        emissionRate: 2.0,
        startRotationVar: 360.0,
        endRotationVar: 360.0,
        radialAccelerationVar: 10.0 / distance,
        tangentialAccelerationVar: 10.0 / distance
    );
    particles.position = const Offset(1024.0, -50.0);
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  set active(bool active) {
    motions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        motions.run(
            new MotionTween<double>((a) => system.opacity = a, system.opacity, 1.0, 2.0
            ));
      } else {
        motions.run(
            new MotionTween<double>((a) => system.opacity = a, system.opacity, 0.0, 0.5
            ));
      }
    }
  }
}
