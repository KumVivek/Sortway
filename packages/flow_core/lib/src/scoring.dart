/// 3 stars = no lives lost, 2 = one lost, 1 = two or more lost.
int starsFor(int livesLost) => (3 - livesLost).clamp(1, 3);

/// Coins for finishing a level: [base] plus [perExtraStar] for each star
/// above one.
int coinsForLevel({
  required int stars,
  required int base,
  int perExtraStar = 10,
}) => base + perExtraStar * (stars.clamp(1, 3) - 1);

/// Daily challenge seed: `yyyymmdd` of the local calendar date.
int dailySeed(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
