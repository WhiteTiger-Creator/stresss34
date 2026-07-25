#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Inspect before changing anything (read-only) ---
# Read the deployment state the runbook requires.
cat /app/docs/deployment_runbook.md || true

# Read the output contract: schemas, key sets, identifier payloads, checksum encodings.
python3 -c "import json;print(json.dumps(json.load(open('/app/docs/rollup_contract.json')),indent=2))"

# Locate the governing CAB entries. The log is long and mostly routine, so index the
# ticketed decisions first, then read the ones that govern each stage.
grep -n "MET-" /app/sample/rollup_review_log.md | head -60 || true
python3 -c "import json;print(json.dumps(json.load(open('/app/docs/rollup_contract.json'))['governing_entry_index'],indent=2))"

# Confirm which entries are superseded rather than governing.
grep -n "Superseded\|Revised" /app/sample/rollup_review_log.md | head -20 || true

# Inspect the current host state and the broken compiler before touching either.
ls -la /usr/local/bin/rollup-metrics /var/lock /app/output 2>&1 || true
getent passwd svc-metrics || echo "svc-metrics not provisioned"
ls -la /etc/cron.d/ 2>&1 || true
sed -n '1,60p' /app/workflow/metric_rollup.py || true

# Read the operational inputs the compile reconciles.
ls -la /app/data || true
python3 -c "import json;d=json.load(open('/app/data/samples.json'));print(len(d),'sample rows')"

# --- Restore the deployment state defined in /app/docs/deployment_runbook.md ---

# Dedicated service account with no interactive shell.
if ! getent passwd svc-metrics >/dev/null; then
  useradd --system --shell /usr/sbin/nologin svc-metrics
fi

# Operator wrapper: executable, targets the live compiler, honors the lock.
cat > /usr/local/bin/rollup-metrics <<'EOF'
#!/bin/sh
LOCK=/var/lock/metrics-rollup.lock
if [ -e "$LOCK" ]; then
  echo "sample compile blocked by existing lock: $LOCK" >&2
  exit 75
fi
exec python3 /app/workflow/metric_rollup.py "$@"
EOF
chmod 0755 /usr/local/bin/rollup-metrics

# Clear the stale lock left by the crashed rollout.
rm -f /var/lock/metrics-rollup.lock

# Reinstate the schedule.
printf '*/5 * * * * svc-metrics /usr/local/bin/rollup-metrics --input /app/data/samples.json --output-dir /app/output\n' \
  > /etc/cron.d/metrics-rollup
chmod 0644 /etc/cron.d/metrics-rollup

# Output directory ownership and mode per runbook.
mkdir -p /app/output
chown svc-metrics:svc-metrics /app/output
chmod 0750 /app/output

# Log directory per runbook: prune the rollout leftover, then hand the directory to
# the service account and drop the world-writable mode.
mkdir -p /var/log/metrics-rollup
rm -f /var/log/metrics-rollup/compile.log.0
chown -R svc-metrics:svc-metrics /var/log/metrics-rollup
chmod 0750 /var/log/metrics-rollup

# Rotation drop-in. The su/create lines keep rotated files owned by svc-metrics.
cat > /etc/logrotate.d/metrics-rollup <<'ROTEOF'
/var/log/metrics-rollup/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    su svc-metrics svc-metrics
    create 0640 svc-metrics svc-metrics
}
ROTEOF
chmod 0644 /etc/logrotate.d/metrics-rollup

# --- Restore the compiler itself and produce the responder outputs ---

cp "${SCRIPT_DIR}/metric_rollup_fixed.py" /app/workflow/metric_rollup.py
chmod +x /app/workflow/metric_rollup.py

/usr/local/bin/rollup-metrics --input /app/data/samples.json --output-dir /app/output
