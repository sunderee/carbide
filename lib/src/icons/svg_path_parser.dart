// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' as ui;

/// Parses an SVG path `d` string into a [ui.Path].
///
/// Supports the full grammar used by the Carbon icon sources: the
/// M/L/H/V/C/S/Q/T/A/Z commands in absolute and relative forms, implicit
/// command repetition, smooth-curve reflection, scientific notation, and
/// compact arc flags. SVG arcs map directly onto [ui.Path.arcToPoint].
///
/// Fidelity of the parse-and-paint pipeline against upstream rasters was
/// established empirically in ADR 0001 (blurred-coverage mismatch 0.000%).
///
/// Throws a [FormatException] on malformed data.
ui.Path parseSvgPath(String d) {
  final _PathScanner s = _PathScanner(d);
  final ui.Path path = ui.Path();
  double x = 0, y = 0;
  double startX = 0, startY = 0;
  double cx = 0, cy = 0;
  String previous = '';

  while (true) {
    final String? command = s.nextCommand();
    if (command == null) {
      break;
    }
    switch (command) {
      case 'M':
      case 'm':
        final bool rel = command == 'm';
        double px = s.nextNumber(), py = s.nextNumber();
        if (rel) {
          px += x;
          py += y;
        }
        path.moveTo(px, py);
        x = startX = px;
        y = startY = py;
        while (s.hasNumber) {
          double lx = s.nextNumber(), ly = s.nextNumber();
          if (rel) {
            lx += x;
            ly += y;
          }
          path.lineTo(lx, ly);
          x = lx;
          y = ly;
        }
      case 'L':
      case 'l':
        do {
          double lx = s.nextNumber(), ly = s.nextNumber();
          if (command == 'l') {
            lx += x;
            ly += y;
          }
          path.lineTo(lx, ly);
          x = lx;
          y = ly;
        } while (s.hasNumber);
      case 'H':
      case 'h':
        do {
          double lx = s.nextNumber();
          if (command == 'h') {
            lx += x;
          }
          path.lineTo(lx, y);
          x = lx;
        } while (s.hasNumber);
      case 'V':
      case 'v':
        do {
          double ly = s.nextNumber();
          if (command == 'v') {
            ly += y;
          }
          path.lineTo(x, ly);
          y = ly;
        } while (s.hasNumber);
      case 'C':
      case 'c':
        do {
          double x1 = s.nextNumber(), y1 = s.nextNumber();
          double x2 = s.nextNumber(), y2 = s.nextNumber();
          double ex = s.nextNumber(), ey = s.nextNumber();
          if (command == 'c') {
            x1 += x;
            y1 += y;
            x2 += x;
            y2 += y;
            ex += x;
            ey += y;
          }
          path.cubicTo(x1, y1, x2, y2, ex, ey);
          cx = x2;
          cy = y2;
          x = ex;
          y = ey;
        } while (s.hasNumber);
      case 'S':
      case 's':
        do {
          double x2 = s.nextNumber(), y2 = s.nextNumber();
          double ex = s.nextNumber(), ey = s.nextNumber();
          if (command == 's') {
            x2 += x;
            y2 += y;
            ex += x;
            ey += y;
          }
          final bool reflect = 'CcSs'.contains(previous);
          final double x1 = reflect ? 2 * x - cx : x;
          final double y1 = reflect ? 2 * y - cy : y;
          path.cubicTo(x1, y1, x2, y2, ex, ey);
          cx = x2;
          cy = y2;
          x = ex;
          y = ey;
          previous = command;
        } while (s.hasNumber);
      case 'Q':
      case 'q':
        do {
          double x1 = s.nextNumber(), y1 = s.nextNumber();
          double ex = s.nextNumber(), ey = s.nextNumber();
          if (command == 'q') {
            x1 += x;
            y1 += y;
            ex += x;
            ey += y;
          }
          path.quadraticBezierTo(x1, y1, ex, ey);
          cx = x1;
          cy = y1;
          x = ex;
          y = ey;
        } while (s.hasNumber);
      case 'T':
      case 't':
        do {
          double ex = s.nextNumber(), ey = s.nextNumber();
          if (command == 't') {
            ex += x;
            ey += y;
          }
          final bool reflect = 'QqTt'.contains(previous);
          final double x1 = reflect ? 2 * x - cx : x;
          final double y1 = reflect ? 2 * y - cy : y;
          path.quadraticBezierTo(x1, y1, ex, ey);
          cx = x1;
          cy = y1;
          x = ex;
          y = ey;
          previous = command;
        } while (s.hasNumber);
      case 'A':
      case 'a':
        do {
          final double rx = s.nextNumber(), ry = s.nextNumber();
          final double rotation = s.nextNumber();
          final bool largeArc = s.nextFlag(), sweep = s.nextFlag();
          double ex = s.nextNumber(), ey = s.nextNumber();
          if (command == 'a') {
            ex += x;
            ey += y;
          }
          path.arcToPoint(
            ui.Offset(ex, ey),
            radius: ui.Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: sweep,
          );
          x = ex;
          y = ey;
        } while (s.hasNumber);
      case 'Z':
      case 'z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('unsupported path command: $command in $d');
    }
    previous = command;
  }
  return path;
}

class _PathScanner {
  _PathScanner(this.source);

  final String source;
  int _i = 0;

  static bool _isCommand(int c) =>
      (c >= 0x41 && c <= 0x5A || c >= 0x61 && c <= 0x7A) &&
      c != 0x65 &&
      c != 0x45;

  void _skip() {
    while (_i < source.length) {
      final int c = source.codeUnitAt(_i);
      if (c == 0x20 || c == 0x2C || c == 0x09 || c == 0x0A || c == 0x0D) {
        _i++;
      } else {
        break;
      }
    }
  }

  String? nextCommand() {
    _skip();
    if (_i >= source.length) {
      return null;
    }
    final int c = source.codeUnitAt(_i);
    if (_isCommand(c)) {
      _i++;
      return String.fromCharCode(c);
    }
    throw FormatException('expected command at $_i in: $source');
  }

  bool get hasNumber {
    _skip();
    if (_i >= source.length) {
      return false;
    }
    final int c = source.codeUnitAt(_i);
    return c == 0x2D || c == 0x2B || c == 0x2E || (c >= 0x30 && c <= 0x39);
  }

  double nextNumber() {
    _skip();
    final int start = _i;
    if (_i < source.length &&
        (source.codeUnitAt(_i) == 0x2D || source.codeUnitAt(_i) == 0x2B)) {
      _i++;
    }
    bool dot = false;
    while (_i < source.length) {
      final int c = source.codeUnitAt(_i);
      if (c >= 0x30 && c <= 0x39) {
        _i++;
      } else if (c == 0x2E && !dot) {
        dot = true;
        _i++;
      } else if (c == 0x65 || c == 0x45) {
        _i++;
        if (_i < source.length &&
            (source.codeUnitAt(_i) == 0x2D || source.codeUnitAt(_i) == 0x2B)) {
          _i++;
        }
      } else {
        break;
      }
    }
    return double.parse(source.substring(start, _i));
  }

  bool nextFlag() {
    _skip();
    final int c = source.codeUnitAt(_i);
    _i++;
    return switch (c) {
      0x30 => false,
      0x31 => true,
      _ => throw FormatException('expected arc flag at ${_i - 1}: $source'),
    };
  }
}
