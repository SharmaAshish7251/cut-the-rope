import 'dart:ui';
import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';

class RopeComponent extends BodyComponent {
  final String id;
  final Vector2 anchorPosition;
  final Body candyBody;
  final double length;
  final bool cuttable;

  Joint? _joint;
  bool _isCut = false;
  bool get isCut => _isCut;
  bool highlighted = false;

  Vector2? _lastCandyPosAtCut;
  double _severElapsed = 0.0;

  Vector2 get segmentStart => body.position;
  Vector2 get segmentEnd   => candyBody.position;

  RopeComponent({
    required this.id,
    required this.anchorPosition,
    required this.candyBody,
    required this.length,
    required this.cuttable,
  }) : super(renderBody: false);

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = anchorPosition;
    return world.createBody(bodyDef);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _createJoint();
  }

  void _createJoint() {
    final dist = (candyBody.position - anchorPosition).length;
    final l = dist > 0.1 ? dist : length;
    final jointDef = DistanceJointDef()
      ..initialize(body, candyBody, anchorPosition, candyBody.position)
      ..length = l
      ..frequencyHz = 0.0
      ..dampingRatio = 0.0;
    final joint = DistanceJoint(jointDef);
    world.createJoint(joint);
    _joint = joint;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isCut) {
      _severElapsed += dt;
    }
  }

  void cut() {
    if (_isCut || _joint == null) return;
    _isCut = true;
    _lastCandyPosAtCut = candyBody.position.clone();
    _severElapsed = 0.0;
    world.destroyJoint(_joint!);
    _joint = null;
    // Keep RopeComponent mounted so anchor pin remains visible on screen
  }

  bool intersectsSwipe(Vector2 from, Vector2 to, double sensitivity) {
    if (_isCut) return false;
    final threshold = (sensitivity / 20.0).clamp(0.6, 1.4);
    return _segDist(from, to, segmentStart, segmentEnd) <= threshold;
  }

  double _segDist(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4) {
    final d1 = p2 - p1;
    final d2 = p4 - p3;
    final r  = p1 - p3;
    final a  = d1.dot(d1);
    final e  = d2.dot(d2);
    final f  = d2.dot(r);
    double s, t;
    if (a <= 1e-4 && e <= 1e-4) return r.length;
    if (a <= 1e-4) {
      s = 0; t = (f / e).clamp(0.0, 1.0);
    } else {
      final c = d1.dot(r);
      if (e <= 1e-4) {
        t = 0; s = (-c / a).clamp(0.0, 1.0);
      } else {
        final b = d1.dot(d2);
        final den = a * e - b * b;
        s = den != 0 ? ((b * f - c * e) / den).clamp(0.0, 1.0) : 0;
        t = (b * s + f) / e;
        if (t < 0) { t = 0; s = (-c / a).clamp(0.0, 1.0); }
        else if (t > 1) { t = 1; s = ((b - c) / a).clamp(0.0, 1.0); }
      }
    }
    return ((p1 + d1 * s) - (p3 + d2 * t)).length;
  }

  @override
  void render(Canvas canvas) {
    const sOff = Offset.zero;

    if (_isCut) {
      // Draw anchor pin remaining on the wall after rope cut
      canvas.drawCircle(const Offset(0, 0.04), 0.22, Paint()..color = const Color(0x40000000));
      canvas.drawCircle(sOff, 0.22, Paint()..color = const Color(0xFF4A3020));
      canvas.drawCircle(
        sOff,
        0.14,
        Paint()..color = highlighted ? const Color(0xFFFFD166) : const Color(0xFFC0A080),
      );

      // Severing fray recoil animation (lasts 0.35s after cut)
      if (_severElapsed < 0.35 && _lastCandyPosAtCut != null) {
        final progress = (_severElapsed / 0.35).clamp(0.0, 1.0);
        final recoilFactor = 1.0 - progress;
        final dir = _lastCandyPosAtCut! - body.position;
        final stubLength = (dir.length * 0.35 * recoilFactor).clamp(0.1, 1.2);
        final norm = dir.normalized();
        final wiggle = math.sin(_severElapsed * 35) * 0.08 * recoilFactor;
        final recoilEnd = Offset(norm.x * stubLength + norm.y * wiggle, norm.y * stubLength - norm.x * wiggle);

        // Frayed threads
        canvas.drawLine(
          sOff,
          recoilEnd,
          Paint()
            ..color = Color.fromRGBO(139, 94, 60, recoilFactor.clamp(0.0, 1.0))
            ..strokeWidth = 0.14 * recoilFactor
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }

    final eOff = Offset(
      candyBody.position.x - body.position.x,
      candyBody.position.y - body.position.y,
    );

    final dist = (candyBody.position - body.position).length;
    final slack = math.max(0.0, length - dist);

    if (slack > 0.05) {
      // Natural rope sag curvature via Quadratic Bezier
      final sag = math.min(1.2, slack * 0.55);
      final controlPoint = Offset(eOff.dx / 2, eOff.dy / 2 + sag);

      final ropePath = Path()
        ..moveTo(sOff.dx, sOff.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, eOff.dx, eOff.dy);

      // Highlight glow when hinted
      if (highlighted) {
        canvas.drawPath(
          ropePath,
          Paint()
            ..color = const Color(0xCCFFD166)
            ..strokeWidth = 0.35
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15),
        );
      }

      // Shadow
      final shadowPath = Path()
        ..moveTo(sOff.dx + 0.04, sOff.dy + 0.04)
        ..quadraticBezierTo(controlPoint.dx + 0.04, controlPoint.dy + 0.04, eOff.dx + 0.04, eOff.dy + 0.04);
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = const Color(0x403A2010)
          ..strokeWidth = 0.18
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Cable body
      canvas.drawPath(
        ropePath,
        Paint()
          ..color = highlighted ? const Color(0xFFFFD166) : const Color(0xFF8B5E3C)
          ..strokeWidth = 0.14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Cable highlight / braid
      final highlightPath = Path()
        ..moveTo(sOff.dx - 0.02, sOff.dy - 0.02)
        ..quadraticBezierTo(controlPoint.dx - 0.02, controlPoint.dy - 0.02, eOff.dx - 0.02, eOff.dy - 0.02);
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = const Color(0x66FFAA66)
          ..strokeWidth = 0.05
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Taut straight cable
      if (highlighted) {
        canvas.drawLine(
          sOff,
          eOff,
          Paint()
            ..color = const Color(0xCCFFD166)
            ..strokeWidth = 0.35
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15),
        );
      }

      // Shadow
      canvas.drawLine(
        Offset(sOff.dx + 0.04, sOff.dy + 0.04),
        Offset(eOff.dx + 0.04, eOff.dy + 0.04),
        Paint()
          ..color = const Color(0x403A2010)
          ..strokeWidth = 0.18
          ..strokeCap = StrokeCap.round,
      );

      // Cable body
      canvas.drawLine(
        sOff,
        eOff,
        Paint()
          ..color = highlighted ? const Color(0xFFFFD166) : const Color(0xFF8B5E3C)
          ..strokeWidth = 0.14
          ..strokeCap = StrokeCap.round,
      );

      // Cable highlight / braid
      canvas.drawLine(
        Offset(sOff.dx - 0.02, sOff.dy - 0.02),
        Offset(eOff.dx - 0.02, eOff.dy - 0.02),
        Paint()
          ..color = const Color(0x66FFAA66)
          ..strokeWidth = 0.05
          ..strokeCap = StrokeCap.round,
      );
    }

    // Anchor pin
    canvas.drawCircle(sOff, 0.22, Paint()..color = const Color(0xFF4A3020));
    canvas.drawCircle(
      sOff,
      0.14,
      Paint()..color = highlighted ? const Color(0xFFFFD166) : const Color(0xFFC0A080),
    );
  }
}
