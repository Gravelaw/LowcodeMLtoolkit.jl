# Runtime sources are digest-pinned in scripts/ci/workflows.json.
ARG NODE_IMAGE
ARG JULIA_IMAGE
ARG UBUNTU_IMAGE
FROM ${NODE_IMAGE} AS node
FROM ${JULIA_IMAGE} AS julia
FROM ${UBUNTU_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates curl git python3 postgresql-client procps xz-utils libatomic1 libstdc++6 && rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
COPY --from=julia /usr/local/julia /usr/local/julia
ENV PATH=/usr/local/julia/bin:$PATH
ENV JULIA_DEPOT_PATH=/cache/julia
ENV npm_config_cache=/cache/npm
ENV CI=true
RUN node --version && npm --version && julia --version
WORKDIR /workspace
