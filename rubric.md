# Rubric — Metrics-Rollup Host Recovery

Agent provisions the dedicated svc-metrics system account with no interactive login shell, ±2
Agent installs the operator wrapper /usr/local/bin/rollup-metrics root-owned at mode 0755, forwarding its arguments to the live compiler and not the missing legacy path, ±2
Agent keeps the wrapper running the compiler as the invoking user, never switching identity via su, sudo, setpriv, setuid or similar, ±2
Agent makes the wrapper exit status 75 and write no output while the run lock /var/lock/metrics-rollup.lock is present, and clears the stale rollout lock during recovery, ±2
Agent installs the cron drop-in /etc/cron.d/metrics-rollup at mode 0644 with the exact runbook job line running the compile as svc-metrics on the given schedule, ±2
Agent sets /app/output to svc-metrics ownership at mode 0750 and not world-writable, ±1
Agent sets /var/log/metrics-rollup to svc-metrics ownership at mode 0750, prunes the unrotated compile.log.0 leftover, and keeps the live compile.log, ±2
Agent installs the logrotate drop-in /etc/logrotate.d/metrics-rollup at mode 0644 covering the compile-log glob with the retention, safety and su/create directives so rotation actually runs and leaves rotated files owned by svc-metrics, ±2
Agent has the scheduled path run end to end: the wrapper invoked as svc-metrics with the cron arguments produces the exact contract outputs, ±3
Agent repairs /app/workflow/metric_rollup.py so rollup_summary.json, gap_windows.json and alert_queue.jsonl match the rollup_contract.json schemas, key sets, identifier payloads and checksum encodings exactly, ±3
Agent applies the later-dated MET review-log decisions where entries disagree, so normalization, dedupe, intervals, policy resolution and fallbacks, attenuation, the debt ledger, scoring, priority and ordering match the change-advisory board's signed-off behaviour, ±3
Agent derives every rollup value at runtime by computing it from the input samples, the fixed source files and the board's rulings, rather than embedding or hardcoding fixed output values, ±2
Agent leaves the frozen reference snapshot /app/workflow/.metric_rollup.original unchanged, ±1
Agent produces correct output on an alternate sample input it has not seen, ±2
Agent produces deterministic, idempotent output identical across repeated runs, ±2

## Verification

Host recovery is graded by focused static and execution checks: the svc-metrics system-account attributes; the operator wrapper's root ownership, exact 0755 mode, live-compiler target, no-privilege-drop property and a lock-guarded exit 75 that writes nothing on either stream and produces no output file; the cron drop-in's mode and exact job line; the ownership and 0750 modes of the output and log directories; the pruned leftover and surviving live log; and the root-owned 0644 logrotate drop-in and a forced logrotate run that must actually rotate the log and leave the recreated log owned by svc-metrics at 0640. A final end-to-end check runs the wrapper as svc-metrics with the cron arguments and matches its outputs against the sealed fixtures.

Compiler correctness is graded by sealed output: the three output files from the primary input, and from an unseen alternate input, are compared by exact SHA-256 against fixtures the agent never sees, so a repair that guesses or embeds fixed values cannot pass. Additional focused checks exercise dedupe, compaction, overlap, policy fallbacks, the debt ledger, thresholds, priority and ordering on crafted inputs, and confirm idempotency, custom output directories, the preserved frozen snapshot, and that the source computes results at runtime.
