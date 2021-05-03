FROM golang:1.16.2 AS builder

COPY . src/
WORKDIR /go/src/dnscrypt-proxy
RUN CGO_ENABLED=0 go build -mod vendor -ldflags="-s -w"


FROM alpine:3.12.4  

WORKDIR /root/
COPY --from=builder /go/src/dnscrypt-proxy/dnscrypt-proxy .
COPY dnscrypt-proxy.toml forwarding-rules.txt ./
RUN touch cloaking-rules.txt

CMD ["./dnscrypt-proxy"] 