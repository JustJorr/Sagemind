import '../models/rule_model.dart';

class RuleScore {
  final RuleModel rule;
  final double score;

  RuleScore(this.rule, this.score);
}

class ExpertEngine {
  // 🔹 Exact match by condition (with optional subject filter)
  static RuleModel? inferFromCondition(
    String input,
    List<RuleModel> rules, {
    String? subjectId,
  }) {
    input = input.toLowerCase();

    for (final r in rules) {
      if (subjectId != null && r.subjectId != subjectId) continue;

      if (r.kondisi.toLowerCase().contains(input)) {
        return r;
      }
    }
    return null;
  }

  // 🔹 Exact match by material (with optional subject filter)
  static RuleModel? inferFromMaterial(
    String materialId,
    List<RuleModel> rules, {
    String? subjectId,
  }) {
    for (final r in rules) {
      if (subjectId != null && r.subjectId != subjectId) continue;

      if (r.materialId == materialId) {
        return r;
      }
    }
    return null;
  }

  // 🔥 Fuzzy Scoring Recommendation Engine
  static List<RuleScore> scoreRulesByCondition(
    String input,
    List<RuleModel> rules, {
    String? subjectId,
  }) {
    input = input.toLowerCase();
    List<RuleScore> outputs = [];

    for (final rule in rules) {
      if (subjectId != null && rule.subjectId != subjectId) continue;

      final kondisi = rule.kondisi.toLowerCase();
      double score = 0;

      // 1) Exact contains → strong score
      if (kondisi.contains(input)) {
        score += 0.6;
      }

      // 2) Word-level fuzzy matching
      final inputWords = input.split(' ');
      for (final w in inputWords) {
        if (w.isEmpty) continue;
        if (kondisi.contains(w)) {
          score += 0.1;
        }
      }

      // 3) Similarity score
      score += _stringSimilarity(input, kondisi) * 0.3;

      if (score > 0) {
        outputs.add(RuleScore(rule, score));
      }
    }

    outputs.sort((a, b) => b.score.compareTo(a.score));
    return outputs;
  }

  // 🔧 Levenshtein similarity helper
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
