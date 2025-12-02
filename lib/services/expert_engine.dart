import '../models/rule_model.dart';

class RuleScore {
  final RuleModel rule;
  final double score;

  RuleScore(this.rule, this.score);
}

class ExpertEngine {
  /// Exact match – earlier function
  static RuleModel? inferFromCondition(String input, List<RuleModel> rules) {
    input = input.toLowerCase();

    for (final r in rules) {
      if (r.kondisi.toLowerCase().contains(input)) {
        return r;
      }
    }
    return null;
  }

  /// Exact material match – earlier function
  static RuleModel? inferFromMaterial(String materialId, List<RuleModel> rules) {
    for (final r in rules) {
      if (r.materialId == materialId) {
        return r;
      }
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // 🔥 Step C — Fuzzy Scoring Recommendation Engine
  // --------------------------------------------------------------------------

  /// Hitung skor kecocokan antara input user dan kondisi rule
  static List<RuleScore> scoreRulesByCondition(
      String input, List<RuleModel> rules) {
    input = input.toLowerCase();

    List<RuleScore> outputs = [];

    for (final rule in rules) {
      final kondisi = rule.kondisi.toLowerCase();

      double score = 0;

      // 1) exact contains → skor besar
      if (kondisi.contains(input)) {
        score += 0.6;
      }

      // 2) fuzzy word matching
      final inputWords = input.split(' ');
      for (final w in inputWords) {
        if (w.isEmpty) continue;
        if (kondisi.contains(w)) {
          score += 0.1;
        }
      }

      // 3) similarity (Levenshtein ratio)
      score += _stringSimilarity(input, kondisi) * 0.3;

      if (score > 0) {
        outputs.add(RuleScore(rule, score));
      }
    }

    // descending sort by score
    outputs.sort((a, b) => b.score.compareTo(a.score));

    return outputs;
  }

  /// Levenshtein similarity for fuzzy matching
  static double _stringSimilarity(String a, String b) {
    int distance = _levenshtein(a, b);
    int maxLen = a.length > b.length ? a.length : b.length;

    if (maxLen == 0) return 1.0;
    return 1.0 - (distance / maxLen);
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<List<int>> dp =
        List.generate(s.length + 1, (_) => List.filled(t.length + 1, 0));

    for (int i = 0; i <= s.length; i++) dp[i][0] = i;
    for (int j = 0; j <= t.length; j++) dp[0][j] = j;

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;

        dp[i][j] = [
          dp[i - 1][j] + 1,        // deletion
          dp[i][j - 1] + 1,        // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[s.length][t.length];
  }
}
