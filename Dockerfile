# TraeWorkAssistant 定制构建：源码编译 + per-key 模型可见性 + 手机 CSS 注入
# 基于官方 docker_main Dockerfile，仅在运行级追加 CSS 注入步骤

# ===== 阶段 1：前端构建 =====
FROM node:20-slim AS web
WORKDIR /build
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

# ===== 阶段 2：Rust 服务端构建 =====
FROM rust:1.97-slim AS server
WORKDIR /build
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY crates/aiwork-core/Cargo.toml crates/aiwork-core/Cargo.toml
COPY crates/aiwork-server/Cargo.toml crates/aiwork-server/Cargo.toml
RUN mkdir -p crates/aiwork-core/src crates/aiwork-server/src \
    && echo 'pub fn __placeholder() {}' > crates/aiwork-core/src/lib.rs \
    && echo 'fn main() {}' > crates/aiwork-server/src/main.rs \
    && cargo build --release -p aiwork-server --bin aiwork-server \
    && rm -rf crates/aiwork-core/src crates/aiwork-server/src
COPY crates ./crates
RUN touch crates/aiwork-core/src/lib.rs crates/aiwork-server/src/main.rs \
    && cargo build --release -p aiwork-server

# ===== 阶段 3：运行级 =====
FROM debian:bookworm-slim AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=server /build/target/release/aiwork-server /app/aiwork-server
COPY --from=web /build/dist /app/dist
ENV AIWORK_DATA_DIR=/app/data \
    AIWORK_WEB_DIST=/app/dist \
    AIWORK_LISTEN_ADDR=0.0.0.0:8080 \
    AIWORK_PORT=8080 \
    AIWORK_DISABLE_LOCAL_QUOTA=1 \
    TZ=Asia/Shanghai
ENV _RJEM_MALLOC_CONF="background_thread:true,dirty_decay_ms:5000,muzzy_decay_ms:5000"
EXPOSE 8080
VOLUME ["/app/data"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${AIWORK_PORT}/health" || exit 1

# 手机 CSS 注入（纯 shell，不依赖 python）
COPY inject-mobile.sh /tmp/inject-mobile.sh
RUN chmod +x /tmp/inject-mobile.sh && /tmp/inject-mobile.sh && rm -f /tmp/inject-mobile.sh

ENTRYPOINT ["/app/aiwork-server"]
