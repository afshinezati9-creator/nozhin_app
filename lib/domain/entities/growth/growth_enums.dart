/// وضعیت‌های رسمی تب توسعه فردی (فاز T0)

enum JourneyStatus {
  draft,
  active,
  paused,
  completed,
  archived,
}

enum ProgramUserStatus {
  notStarted,
  learning,
  ready,
  inProgress,
  paused,
  done,
  archived,
}

enum SessionStatus {
  inProgress,
  saved,
  evaluated,
  abandoned,
}

enum CompletionLevel {
  full,
  partial,
  none,
}

enum GrowthNeedArea {
  focus,
  habit,
  time,
  goal,
  decision,
  selfKnowledge,
  unknown,
}

/// قدم بعدی بعد از هر نتیجه
enum NextStepKind {
  continueSame,
  makeEasier,
  tryOtherMethod,
  pause,
  review,
}
