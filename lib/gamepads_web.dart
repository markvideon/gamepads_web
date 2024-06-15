// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:gamepads_platform_interface/api/gamepad_controller.dart';
import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/gamepads_platform_interface.dart';
import 'package:web/web.dart' as web;

/// A web implementation of the GamepadsWebPlatform of the GamepadsWeb plugin.
class GamepadsWeb extends GamepadsPlatformInterface {
  GamepadsWeb() {
    // Get initial gamepads
    final jsGamepads = web.document.defaultView!.navigator.getGamepads();

    final dartGamepads = jsGamepads.toDart;
    if (dartGamepads.isEmpty) {
      debugPrint('No gamepads');
    } else {
      final candidates = dartGamepads.where((e) => e.isDefinedAndNotNull);
      debugPrint('${candidates.length} gamepads');
      candidates.forEach((element) {
        addGamepad(element!);
      });
    }

    // Setup device listeners
    web.document.defaultView!.addEventListener("gamepadconnected", (web.GamepadEvent event) {
      addGamepad(event.gamepad);
    }.toJS);

    web.document.defaultView!.addEventListener("gamepaddisconnected", (web.GamepadEvent event) {
      debugPrint('gamepaddisconnected: ${event.gamepad.id}');
      removeGamepad(event.gamepad);
    }.toJS);

    // Setup event listeners. Expect worker file in host project.
    web.Worker worker = web.Worker.new('worker.js');
    worker.addEventListener("message", (web.MessageEvent input) {
      if (input.data == "PING") {
        final jsGamepads = web.document.defaultView!.navigator.getGamepads();
        final dartGamepads = jsGamepads.toDart.where((e) => e.isDefinedAndNotNull)
          .map((e) => e!)
          .toList(growable: false);

        dartGamepads.forEach((gamepad) {
          final id = gamepad.index.toString();
          bool containsKey =
              _oldButtons.containsKey(id) &&
              _oldAxes.containsKey(id);

          if (containsKey) {
            final buttons = gamepad.buttons.toDart;
            // debugPrint('buttons.length: ${buttons.length}');
            buttons.forEachIndexed((idx, button) {
              if (button.pressed != _oldButtons[id]!.elementAt(idx).pressed) {
                debugPrint('reporting button event. button[$idx] != _oldButtons[$id]!.elementAt($idx)');
                debugPrint('_oldButtons[id]!.elementAt(idx): ${_oldButtons[id]!.elementAt(idx)}');
                // report event
                _streamController.add(GamepadEvent(
                    gamepadId: id,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    type: KeyType.button,
                    key: idx.toString(),
                    value: button.pressed ? 1.0 : 0.0)
                );
              }
            });

            _oldButtons[id] = buttons;
            final axes = gamepad.axes.toDart
                .map((e) => e.toDartDouble)
                .toList(growable: false);
            // debugPrint('axes length: ${axes.length}');
            axes.forEachIndexed((idx, axis) {
              // debugPrint('axis $idx: $axis');
              if (axis - _oldAxes[id]!.elementAt(idx).abs() > epsilon) {
                debugPrint('reporting axis event');
                // report event
                _streamController.add(GamepadEvent(
                    gamepadId: id,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    type: KeyType.analog,
                    key: idx.toString(),
                    value: axis)
                );
              }
            });

            _oldAxes[id] = axes;
          } else {
            print('Did not contain key!');
          }
        });
      }
    }.toJS);

    // Start the worker loop
    worker.postMessage("START".toJS);
  }

  static const epsilon = 0.01;

  final Map<String, web.Gamepad> _gamepads = {};
  final Map<String, List<web.GamepadButton>> _oldButtons = {};
  final Map<String, List<num>> _oldAxes = {};

  addGamepad(web.Gamepad candidate) {
    final id = candidate.index.toString();
    _gamepads[id] = candidate;
    final buttons = candidate.buttons.toDart;
    _oldButtons[id] = buttons;
    final axes = candidate.axes.toDart
        .map((e) => e.toDartDouble)
        .toList(growable: false);
    _oldAxes[id] = axes;
    debugPrint('${_gamepads.length} gamepads');
  }

  removeGamepad(web.Gamepad candidate) {
    final id = candidate.index.toString();
    _gamepads.remove(id);
    _oldAxes.remove(id);
    _oldButtons.remove(id);
    debugPrint('${_gamepads.length} gamepads');

  }

  // ToDo: Consider adding close method to platform interface. Can't currently
  // close this stream.
  final StreamController<GamepadEvent> _streamController = StreamController();

  static void registerWith(Registrar registrar) {
    GamepadsPlatformInterface.instance = GamepadsWeb();
  }

  @override
  Stream<GamepadEvent> get gamepadEventsStream => _streamController.stream;

  @override
  Future<List<GamepadController>> listGamepads() async {
    return _gamepads.values.map((e) =>
        GamepadController(
          id: e.index.toString(),
          name: e.id
        )
    ).toList(growable: false);
  }
}
