# Support setting various labels on the final image
ARG TARGETOS TARGETARCH

# Build Geth in a stock Go builder container
FROM golang:1.23-alpine AS builder

RUN apk add --no-cache gcc musl-dev linux-headers git

# Get dependencies - will also be cached if we won't change go.mod/go.sum
COPY go.mod /go-ethereum/
COPY go.sum /go-ethereum/
RUN cd /go-ethereum && go mod download

ADD . /go-ethereum
RUN cd /go-ethereum && GOOS=$TARGETOS GOARCH=$TARGETARCH go run build/ci.go install -static ./cmd/geth

# Pull Geth into a second stage deploy alpine container
FROM alpine:latest

# Add some metadata labels to help programmatic image consumption
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

LABEL commit="$COMMIT" version="$VERSION" buildnum="$BUILDNUM"
LABEL org.opencontainers.image.source=https://github.com/gustavogama-cll/go-ethereum
LABEL org.opencontainers.image.description="Patched go-ethereum, resetting the --dev.period unit to milliseconds"
LABEL org.opencontainers.image.licenses=LGPL-3,GPL-3.0

RUN apk add --no-cache ca-certificates
COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/

EXPOSE 8545 8546 30303 30303/udp
ENTRYPOINT ["geth"]
