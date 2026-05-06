FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    make \
    pkg-config \
    # Network / fetch
    curl \
    wget \
    gnupg \
    ca-certificates \
    apt-transport-https \
    # Utilities
    jq \
    unzip \
    zip \
    git \
    # Python runtime (uv manages versions; system python for scripts)
    python3 \
    python3-venv \
    # YAML / validation
    yamllint \
  && rm -rf /var/lib/apt/lists/*

# ── Node.js (LTS via NodeSource) ──────────────────────────────────────────────
ARG NODE_VERSION=22
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# ── .NET SDK ──────────────────────────────────────────────────────────────────
ARG DOTNET_VERSION=9.0
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
    --channel "${DOTNET_VERSION}" \
    --install-dir /usr/local/dotnet
ENV PATH="/usr/local/dotnet:${PATH}"
ENV DOTNET_ROOT="/usr/local/dotnet"

# ── uv (Python package/project manager) ──────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
  && mv /root/.local/bin/uv /usr/local/bin/uv \
  && mv /root/.local/bin/uvx /usr/local/bin/uvx

# ── Terraform ────────────────────────────────────────────────────────────────
ARG TERRAFORM_VERSION=1.10.5
RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    -o /tmp/terraform.zip \
  && unzip /tmp/terraform.zip -d /usr/local/bin/ \
  && rm /tmp/terraform.zip

# ── GitHub CLI ───────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

# ── Non-root dev user ─────────────────────────────────────────────────────────
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
  && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}" \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME} \
  && usermod -aG docker "${USERNAME}" 2>/dev/null || true

USER ${USERNAME}

# uv and dotnet tools on PATH for the dev user
ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.dotnet/tools:${PATH}"
