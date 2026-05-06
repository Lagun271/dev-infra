# general devcontainer

A single general-purpose devcontainer for all work. Split into a project-specific container only when conflicting tool versions or special dependencies make that necessary.

## What's inside

| Layer | Tools |
|---|---|
| System packages | build-essential, make, curl, jq, yamllint, git |
| Node | LTS (NodeSource), npm |
| Python | system python3, uv (project/version manager) |
| .NET | SDK (configurable via `DOTNET_VERSION` build arg) |
| Infra CLIs | Terraform, GitHub CLI |
| npm globals | see `packages/npm-global.txt` |

## Usage

Open any repo folder in VS Code and choose **Reopen in Container**, or run:

```bash
devcontainer open .
```

VS Code will build the image on first open (a few minutes) and cache it for subsequent opens.

## Customizing

- Add an apt package: edit the `RUN apt-get install` block in `Dockerfile`, rebuild.
- Add a global npm tool: add to `packages/npm-global.txt`, run `post-create.sh` or rebuild.
- Add a Python tool: use `uv tool install <pkg>` inside the container (idempotent across rebuilds if added to `post-create.sh`).
- Add a .NET global tool: `dotnet tool install -g <pkg>` and persist in `post-create.sh`.

## What stays outside

- Secrets and tokens — mount via environment variables or volume from the host.
- Machine-specific files — use VS Code's `localEnv` or workspace mounts.
- RobotStudio and Windows GUI tools — Windows host only.
