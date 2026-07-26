FROM public.ecr.aws/docker/library/python:3.13-slim-bookworm@sha256:01f42367a0a94ad4bc17111776fd66e3500c1d87c15bbd6055b7371d39c124fb

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tmux \
        asciinema \
        cron \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.lock /tmp/requirements.lock
RUN python3 -m pip install --no-cache-dir --no-deps \
        -r /tmp/requirements.lock

WORKDIR /app

COPY app/ /app/
RUN cp /app/workflow/metric_rollup.py /app/workflow/.metric_rollup.original \
    && chmod a-w /app/workflow/.metric_rollup.original

# Host state left behind by the failed pager-policy rollout.
RUN printf '#!/bin/sh\nexec python3 /app/workflow/metric_rollup.py.legacy "$@"\n' > /usr/local/bin/rollup-metrics \
    && chmod 0644 /usr/local/bin/rollup-metrics \
    && mkdir -p /var/lock \
    && printf '4711\n' > /var/lock/metrics-rollup.lock \
    && rm -f /etc/cron.d/metrics-rollup \
    && mkdir -p /app/output \
    && chmod 0777 /app/output

# Additional host state left behind by the rollout.
RUN mkdir -p /var/log/metrics-rollup \
    && chmod 0777 /var/log/metrics-rollup \
    && printf 'rollout 4711 aborted mid-compile\n' > /var/log/metrics-rollup/compile.log.0 \
    && printf '' > /var/log/metrics-rollup/compile.log \
    && rm -f /etc/logrotate.d/metrics-rollup
