import 'dart:math' as math;

import '../../room_design/models/listening_position.dart';
import '../../room_design/models/room_position.dart';
import '../../room_design/models/room_state.dart';
import '../models/optimization_instruction.dart';
import '../models/optimization_result.dart';
import '../models/sweet_spot_result.dart';
import 'aiming_calculator.dart';
import 'optimization_instruction_generator.dart';
import 'room_context_quality_adjuster.dart';
import 'sweet_spot_calculator.dart';

class RoomOptimizer {
  const RoomOptimizer();

  static const double _stepMeters = 0.1;
  static const int _maxIterations = 24;
  static const double _minSpeakerSpacingMeters = 0.6;
  static const double _minSpeakerSideWallClearanceMeters = 0.35;
  static const double _minListenerSideWallClearanceMeters = 0.3;

  OptimizationResult optimize(RoomState initial) {
    const sweetSpotCalculator = SweetSpotCalculator();
    const instructionGenerator = OptimizationInstructionGenerator();
    const qualityAdjuster = RoomContextQualityAdjuster();

    final safeInitial = _snapStateToValid(initial);
    var current = _withRecommendedToeIn(safeInitial);
    var best = current;
    var bestAdjustedScore = qualityAdjuster.apply(
      base: sweetSpotCalculator.calculate(
        leftSpeaker: best.leftSpeaker,
        rightSpeaker: best.rightSpeaker,
        listeningPosition: best.listeningPosition,
      ),
      state: best,
    );
    var bestObjective = _objectiveScore(best, bestAdjustedScore);

    for (var iteration = 0; iteration < _maxIterations; iteration++) {
      var improved = false;

      for (final candidate in _neighbors(best)) {
        if (!_isValid(candidate)) {
          continue;
        }

        final candidateWithToeIn = _withRecommendedToeIn(candidate);
        final candidateBaseScore = sweetSpotCalculator.calculate(
          leftSpeaker: candidateWithToeIn.leftSpeaker,
          rightSpeaker: candidateWithToeIn.rightSpeaker,
          listeningPosition: candidateWithToeIn.listeningPosition,
        );
        final candidateAdjustedScore = qualityAdjuster.apply(
          base: candidateBaseScore,
          state: candidateWithToeIn,
        );
        final candidateObjective =
            _objectiveScore(candidateWithToeIn, candidateAdjustedScore);

        if (_isBetter(candidateObjective, bestObjective)) {
          best = candidateWithToeIn;
          bestAdjustedScore = candidateAdjustedScore;
          bestObjective = candidateObjective;
          improved = true;
        }
      }

      if (!improved) {
        break;
      }
    }

    current = _withRecommendedToeIn(safeInitial);
    final currentBaseScore = sweetSpotCalculator.calculate(
      leftSpeaker: current.leftSpeaker,
      rightSpeaker: current.rightSpeaker,
      listeningPosition: current.listeningPosition,
    );
    final currentAdjustedScore =
        qualityAdjuster.apply(base: currentBaseScore, state: current);

    final List<OptimizationInstruction> instructions =
        bestAdjustedScore.triangleAccuracy >
                currentAdjustedScore.triangleAccuracy
            ? instructionGenerator.generate(current: current, optimized: best)
            : const <OptimizationInstruction>[];

    return OptimizationResult(
      currentScore: currentAdjustedScore,
      optimizedScore: bestAdjustedScore,
      optimizedState: best,
      instructions: instructions,
    );
  }

  bool _isBetter(double next, double current) => next > current + 0.002;

  Iterable<RoomState> _neighbors(RoomState state) sync* {
    final offsets = <RoomPosition>[
      const RoomPosition(_stepMeters, 0),
      const RoomPosition(-_stepMeters, 0),
      const RoomPosition(0, _stepMeters),
      const RoomPosition(0, -_stepMeters),
      const RoomPosition(_stepMeters, _stepMeters),
      const RoomPosition(-_stepMeters, _stepMeters),
      const RoomPosition(_stepMeters, -_stepMeters),
      const RoomPosition(-_stepMeters, -_stepMeters),
    ];

    for (final delta in offsets) {
      yield state.copyWith(
        leftSpeaker: state.leftSpeaker.copyWith(
          position: _shift(state.leftSpeaker.position, delta),
        ),
      );
      yield state.copyWith(
        rightSpeaker: state.rightSpeaker.copyWith(
          position: _shift(state.rightSpeaker.position, delta),
        ),
      );
      yield state.copyWith(
        listeningPosition: state.listeningPosition.copyWith(
          position: _shift(state.listeningPosition.position, delta),
        ),
      );
    }
  }

  RoomPosition _shift(RoomPosition point, RoomPosition delta) {
    return RoomPosition(point.x + delta.x, point.y + delta.y);
  }

  RoomState _snapStateToValid(RoomState state) {
    return state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(
        position: _nearestValidPoint(
          state,
          state.leftSpeaker.position,
          minSideWallClearance: _minSpeakerSideWallClearanceMeters,
        ),
      ),
      rightSpeaker: state.rightSpeaker.copyWith(
        position: _nearestValidPoint(
          state,
          state.rightSpeaker.position,
          minSideWallClearance: _minSpeakerSideWallClearanceMeters,
        ),
      ),
      listeningPosition: state.listeningPosition.copyWith(
        position: _nearestValidPoint(
          state,
          state.listeningPosition.position,
          minSideWallClearance: _minListenerSideWallClearanceMeters,
        ),
      ),
    );
  }

  RoomPosition _nearestValidPoint(
    RoomState state,
    RoomPosition seed, {
    required double minSideWallClearance,
  }) {
    if (_isPointValid(
      state,
      seed,
      minSideWallClearance: minSideWallClearance,
    )) {
      return seed;
    }

    final room = state.room;
    final maxRadius = room.widthMeters > room.lengthMeters
        ? room.widthMeters
        : room.lengthMeters;

    for (var radius = 0.05; radius <= maxRadius; radius += 0.05) {
      for (var deg = 0; deg < 360; deg += 15) {
        final radians = deg * math.pi / 180;
        final candidate = RoomPosition(
          (seed.x + math.cos(radians) * radius)
              .clamp(0.0, room.widthMeters)
              .toDouble(),
          (seed.y + math.sin(radians) * radius)
              .clamp(0.0, room.lengthMeters)
              .toDouble(),
        );
        if (_isPointValid(
          state,
          candidate,
          minSideWallClearance: minSideWallClearance,
        )) {
          return candidate;
        }
      }
    }

    return RoomPosition(
      seed.x
          .clamp(minSideWallClearance, room.widthMeters - minSideWallClearance)
          .toDouble(),
      seed.y.clamp(0.0, room.lengthMeters).toDouble(),
    );
  }

  bool _isPointValid(
    RoomState state,
    RoomPosition point, {
    required double minSideWallClearance,
  }) {
    final room = state.room;
    final insideRoom = point.x >= 0 &&
        point.x <= room.widthMeters &&
        point.y >= 0 &&
        point.y <= room.lengthMeters;
    if (!insideRoom) return false;

    final leftGap = point.x;
    final rightGap = room.widthMeters - point.x;
    if (leftGap < minSideWallClearance || rightGap < minSideWallClearance) {
      return false;
    }

    for (final blocker in state.blockerZones) {
      if (blocker.contains(point)) return false;
    }
    return true;
  }

  bool _isValid(RoomState state) {
    final leftValid = _isPointValid(
      state,
      state.leftSpeaker.position,
      minSideWallClearance: _minSpeakerSideWallClearanceMeters,
    );
    final rightValid = _isPointValid(
      state,
      state.rightSpeaker.position,
      minSideWallClearance: _minSpeakerSideWallClearanceMeters,
    );
    final listenerValid = _isPointValid(
      state,
      state.listeningPosition.position,
      minSideWallClearance: _minListenerSideWallClearanceMeters,
    );

    if (!leftValid || !rightValid || !listenerValid) {
      return false;
    }

    if (state.leftSpeaker.position.x >= state.rightSpeaker.position.x) {
      return false;
    }

    return state.leftSpeaker.position.distanceTo(state.rightSpeaker.position) >=
        _minSpeakerSpacingMeters;
  }

  double _objectiveScore(RoomState state, SweetSpotResult score) {
    var result = score.triangleAccuracy;

    result -= _clearancePenalty(
      state.leftSpeaker.position.x,
      targetMeters: 0.6,
      weight: 0.12,
    );
    result -= _clearancePenalty(
      state.room.widthMeters - state.rightSpeaker.position.x,
      targetMeters: 0.6,
      weight: 0.12,
    );

    final listenerSideGap = math.min(
      state.listeningPosition.position.x,
      state.room.widthMeters - state.listeningPosition.position.x,
    );
    result -= _clearancePenalty(
      listenerSideGap,
      targetMeters: 0.5,
      weight: 0.06,
    );

    return result;
  }

  double _clearancePenalty(
    double gapMeters, {
    required double targetMeters,
    required double weight,
  }) {
    if (gapMeters >= targetMeters) return 0;
    final deficitRatio = (targetMeters - gapMeters) / targetMeters;
    return deficitRatio * weight;
  }

  RoomState _withRecommendedToeIn(RoomState state) {
    const aimingCalculator = AimingCalculator();
    final aimingPoint = aimingCalculator.calculateRecommendedAimingPoint(
      leftSpeaker: state.leftSpeaker,
      rightSpeaker: state.rightSpeaker,
      listeningPosition: state.listeningPosition,
    );

    return state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(
        toeInDegrees: aimingCalculator.calculateRequiredToeIn(
          speaker: state.leftSpeaker,
          targetPoint: aimingPoint,
        ),
      ),
      rightSpeaker: state.rightSpeaker.copyWith(
        toeInDegrees: aimingCalculator.calculateRequiredToeIn(
          speaker: state.rightSpeaker,
          targetPoint: aimingPoint,
        ),
      ),
      listeningPosition:
          ListeningPosition(position: state.listeningPosition.position),
    );
  }
}
