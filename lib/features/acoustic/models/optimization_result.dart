import '../../room_design/models/room_state.dart';
import 'optimization_instruction.dart';
import 'sweet_spot_result.dart';

class OptimizationResult {
  final SweetSpotResult currentScore;
  final SweetSpotResult optimizedScore;
  final RoomState optimizedState;
  final List<OptimizationInstruction> instructions;

  const OptimizationResult({
    required this.currentScore,
    required this.optimizedScore,
    required this.optimizedState,
    required this.instructions,
  });

  double get scoreDelta =>
      optimizedScore.triangleAccuracy - currentScore.triangleAccuracy;

  bool get hasMeaningfulImprovement => scoreDelta >= 0.01;
}
