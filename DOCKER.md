# 🐳 Dockerfile – Tricentis Simulation Agent

This document explains the `Dockerfile` at the root of this repository, which packages the **Tricentis Simulator Agent** into a container image.

---

## 📦 What It Builds

The image runs `Tricentis.Simulator.Agent`, loading simulation files from a mounted `/workspace` directory and serving them over HTTP on the exposed port range.

| Aspect | Value |
|--------|-------|
| Base image | `mcr.microsoft.com/dotnet/aspnet:10.0` (.NET 10, current LTS) |
| Workspace | `/workspace` (mount your simulation `.yml`/`.yaml` files here) |
| App directory | `/app` |
| Exposed ports | `17070-17077` |
| Default listen port | `17070` (`-p 17070`) |
| User | Runs as non-root user `simulator` (uid `1000`, gid `2000`) |

---

## 🔧 How It Works

### 1. Base Image

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0
```

Uses the official ASP.NET Core runtime image for **.NET 10**, the current Long-Term Support (LTS) release. Only the runtime (not the SDK) is required since the agent binary is copied in pre-built.

### 2. Non-Root User

```dockerfile
RUN addgroup --group simulator --gid 2000 && adduser --uid 1000 --gid 2000 --disabled-password --gecos '' "simulator"
...
USER simulator:simulator
```

A dedicated `simulator` user/group is created and given ownership of `/app` and `/workspace`. The container runs as this non-root user rather than root, following container security best practices.

### 3. Application and Workspace Directories

```dockerfile
RUN mkdir /workspace
RUN chown -R simulator:simulator /app
RUN chown -R simulator:simulator /workspace
COPY * /app/
```

- `/app` receives the built agent binaries and files from the build context.
- `/workspace` is intended to be mounted as a volume containing your simulation configuration files.

### 4. OpenSSL Legacy Compatibility

```dockerfile
COPY --from=mcr.microsoft.com/dotnet/aspnet:7.0 /etc/ssl/openssl.cnf /etc/ssl/openssl.cnf
```

Starting with the Debian 12 (bookworm)-based .NET 8 images, OpenSSL's default configuration raised its security level and dropped TLS 1.0/1.1 support. Simulated targets or clients that still rely on older TLS versions or weaker ciphers can fail to connect against that stricter default.

This line copies the more permissive `openssl.cnf` shipped with the .NET 7 image (based on Debian 11 "bullseye", OpenSSL 1.1.1) into the final image, restoring compatibility with legacy TLS clients/servers. This override is intentionally pinned to an older image and is independent of the primary runtime version above — it should **not** be bumped when the base image is upgraded.

### 5. Ports and Entrypoint

```dockerfile
EXPOSE 17070-17077
ENTRYPOINT ["/app/Tricentis.Simulator.Agent", "/workspace", "-p 17070", "--no-ui"]
```

The agent is started against `/workspace`, listening on port `17070` (additional ports up to `17077` are reserved/exposed for simulations that bind extra ports), with `--no-ui` since the container runs headless.

---

## 🛠 Building and Running

### Build

```bash
docker build -t tricentis-simulator-agent .
```

### Run

```bash
docker run -d \
  -p 17070-17077:17070-17077 \
  -v "$(pwd)/examples:/workspace" \
  tricentis-simulator-agent
```

This mounts a local folder containing your simulation YAML files (e.g. one of the `examples/` folders in this repository) into `/workspace` and exposes the simulation port range to the host.

---

## 🔄 Keeping the Image Up to Date

- Bump the version tag in the `FROM` line (currently `10.0`) when a newer .NET LTS/STS release becomes available.
- Leave the `COPY --from=mcr.microsoft.com/dotnet/aspnet:7.0 ...` line as-is — it deliberately references an older image for its more permissive OpenSSL defaults, not for its runtime.
