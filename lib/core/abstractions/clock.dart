/// Clock abstraction for testable time reads. No scheduling logic.
abstract interface class Clock {
  DateTime now();
}
