ARG UPSTREAM_IMAGE
ARG UPSTREAM_DIGEST_ARM64

FROM node:22-alpine AS builder
RUN apk add --no-cache curl build-base python3 sqlite && \
    npm install -g pnpm@9
ARG VERSION
ENV COMMIT_TAG=${VERSION}
RUN mkdir /build && \
    curl -fsSL "https://github.com/fallenbagel/jellyseerr/archive/v${VERSION}.tar.gz" | tar xzf - -C "/build" --strip-components=1 && \
    cd /build && \
    CYPRESS_INSTALL_BINARY=0 pnpm install --frozen-lockfile && \
    pnpm build && \
    pnpm cache delete


FROM ${UPSTREAM_IMAGE}@${UPSTREAM_DIGEST_ARM64}
EXPOSE 5055
ARG IMAGE_STATS
ENV IMAGE_STATS=${IMAGE_STATS} WEBUI_PORTS="5055/tcp,5055/udp"

RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community pnpm

COPY --from=builder /build/dist "${APP_DIR}/dist"
COPY --from=builder /build/.next "${APP_DIR}/.next"
COPY --from=builder /build/node_modules "${APP_DIR}/node_modules"

ARG VERSION
RUN curl -fsSL "https://github.com/fallenbagel/jellyseerr/archive/v${VERSION}.tar.gz" | tar xzf - -C "${APP_DIR}" --strip-components=1 && \
    echo '{"commitTag": "'"${VERSION}"'"}' > "${APP_DIR}/committag.json" && \
    rm -rf "${APP_DIR}/config" && ln -s "${CONFIG_DIR}" "${APP_DIR}/config" && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

COPY root/ /
