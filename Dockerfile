FROM alpine:latest

ARG TARGETARCH

WORKDIR /app

# Install dependencies
RUN apk add --no-cache curl jq ca-certificates openssl tzdata

# Download Sing-box
RUN version=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r .tag_name) && \
    case "$TARGETARCH" in \
        "amd64") SB_ARCH="amd64" ;; \
        "arm64") SB_ARCH="arm64" ;; \
        *) echo "Unsupported arch"; exit 1 ;; \
    esac && \
    curl -L "https://github.com/SagerNet/sing-box/releases/download/${version}/sing-box-${version#v}-linux-${SB_ARCH}.tar.gz" | tar -xz && \
    mv sing-box-*/sing-box /usr/local/bin/ && \
    rm -rf sing-box-*

# Copy config entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
