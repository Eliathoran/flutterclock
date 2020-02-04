import 'package:flutter/material.dart';

class ImageChangerEngine extends ChangeNotifier{

  Map<int,AnimatedOpacity> _images;
  int _currentIndex = 1;
  int _nextIndex = 2;
  static Map<int, double> _opacities = Map<int, double>();
  static final _duration = Duration(milliseconds: 2300);

  ImageChangerEngine({
    Map<int,Image> images,
    }): _images = images.map((key, image) {
      _opacities[key] = 1.0;
      return MapEntry(key,
          AnimatedOpacity(
          child: image,
          duration: _duration,
          opacity: _opacities[key],
          )
        );
      }
    );

  AnimatedOpacity get currentImage{
    return _images[_currentIndex];
  }

  AnimatedOpacity get nextImage{
    return _images[_nextIndex];
  }

  set nextImageIndex(int imageIndex){
    _nextIndex = imageIndex;
  }

  set currentImageIndex(int imageIndex){
    _currentIndex = imageIndex;
  }

  void cycleImages() async{
    if (_currentIndex != _nextIndex){
      _opacities[_currentIndex] = 0.0;
      _opacities[_nextIndex] = 1.0;
      _images[_currentIndex] = AnimatedOpacity(
        child: _images[_currentIndex].child,
        duration: _duration,
        opacity: _opacities[_currentIndex],
      );
      _images[_nextIndex] = AnimatedOpacity(
        child: _images[_nextIndex].child,
        duration: _duration,
        opacity: _opacities[_nextIndex],
      );
      notifyListeners();
      await new Future.delayed(_duration);
      int previousIndex = _currentIndex;
      _currentIndex = _nextIndex;
      _nextIndex = previousIndex;
      _opacities[previousIndex] = 1.0;
      notifyListeners();
      _images[previousIndex] = AnimatedOpacity(
        child: _images[previousIndex].child,
        duration: _duration,
        opacity: _opacities[previousIndex],
      );
    }
  }
}