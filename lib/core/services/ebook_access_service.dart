/// Tracks which ebooks the user has unlocked (by watching a rewarded ad)
/// for the current app session only. In-memory by design — this singleton
/// is recreated fresh on every app launch, so a closed-and-reopened app
/// always requires watching the ad again.
class EbookAccessService {
  final Set<String> _unlockedIds = {};

  bool isUnlocked(String bookId) => _unlockedIds.contains(bookId);

  void unlock(String bookId) => _unlockedIds.add(bookId);
}
