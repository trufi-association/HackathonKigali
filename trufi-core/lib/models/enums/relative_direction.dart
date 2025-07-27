enum RelativeDirection {
  depart,
  hardLeft,
  left,
  slightlyLeft,
  continue_,
  slightlyRight,
  right,
  hardRight,
  circleClockwise,
  circleCounterclockwise,
  elevator,
  uturnLeft,
  uturnRight,
  enterStation,
  exitStation,
  followSigns,
}

RelativeDirection getRelativeDirectionByString(String direction) {
  return RelativeDirectionExtension.names.keys.firstWhere(
    (key) => key.name == direction,
    orElse: () => RelativeDirection.continue_,
  );
}

extension RelativeDirectionExtension on RelativeDirection {
  static const names = <RelativeDirection, String>{
    RelativeDirection.depart: 'DEPART',
    RelativeDirection.hardLeft: 'HARD_LEFT',
    RelativeDirection.left: 'LEFT',
    RelativeDirection.slightlyLeft: 'SLIGHTLY_LEFT',
    RelativeDirection.continue_: 'CONTINUE',
    RelativeDirection.slightlyRight: 'SLIGHTLY_RIGHT',
    RelativeDirection.right: 'RIGHT',
    RelativeDirection.hardRight: 'HARD_RIGHT',
    RelativeDirection.circleClockwise: 'CIRCLE_CLOCKWISE',
    RelativeDirection.circleCounterclockwise: 'CIRCLE_COUNTERCLOCKWISE',
    RelativeDirection.elevator: 'ELEVATOR',
    RelativeDirection.uturnLeft: 'UTURN_LEFT',
    RelativeDirection.uturnRight: 'UTURN_RIGHT',
    RelativeDirection.enterStation: 'ENTER_STATION',
    RelativeDirection.exitStation: 'EXIT_STATION',
    RelativeDirection.followSigns: 'FOLLOW_SIGNS',
  };

  String get name => names[this] ?? 'CONTINUE';
}
