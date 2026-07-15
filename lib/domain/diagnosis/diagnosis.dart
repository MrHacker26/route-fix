/// Diagnosis rules and engine (consumes service outputs only).
library;

export 'engine/diagnosis_engine.dart';
export 'engine/diagnosis_evidence.dart';
export 'engine/diagnosis_observations.dart';
export 'engine/health_score_calculator.dart';
export 'rules/diagnosis_rule.dart';
export 'rules/diagnosis_rule_result.dart';
export 'rules/dns_failure_rule.dart';
export 'rules/github_connectivity_rule.dart';
export 'rules/ipv6_latency_rule.dart';
export 'rules/ipv6_unavailable_rule.dart';
export 'rules/pypi_latency_rule.dart';
