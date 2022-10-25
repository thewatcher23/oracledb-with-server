FROM golang:1.17.3-alpine3.13 as builder

ARG projectKey
ARG http_proxy
ARG https_proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG no_proxy
ARG VERSION
ARG BUILD_INFO
ARG PROTOC_VERSION=3.14.0
ARG GLIBC_VERSION=2.32-r0

LABEL builder=$projectKey
ENV projectKey=$projectKey

RUN apk update && \
    apk add --no-cache protobuf=3.13.0-r2 \
                       bash=5.1.16-r0 \
                       git=2.30.5-r0 \
                       build-base=0.5-r3 \
                       gcc=10.2.1_pre1-r3 \
                       ca-certificates=20220614-r0  \
                       tzdata=2022c-r0 \
                       docker=20.10.3-r1 \
                       curl=7.79.1-r2 \
                       python3=3.8.10-r0 \
                       unzip=6.0-r9 \
                       python3-dev=3.8.10-r0 \
                       py3-pip=20.3.4-r0 &&\
    update-ca-certificates && \
    pip install --no-cache-dir frigate==0.4.0 && \
    adduser -D -g '' appuser

WORKDIR /app/

RUN GO111MODULE=on go install github.com/go-task/task/v3/cmd/task@v3.12.0 && \
    GO111MODULE=on go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.27.1 && \
    GO111MODULE=on go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0 &&\
    GO111MODULE=on go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.45.2

# Copy the build code
#COPY Taskfile.yaml Taskfile.yaml
#COPY scripts scripts
#COPY .golangci.yaml .golangci.yaml

# Download dependencies
COPY app/go.mod ./
# COPY app/go.sum ./
#RUN task deps

# Copy the docs
#COPY deploy-config/README.md deploy-config/README.md

# Copy the source code
COPY app/*.go ./
COPY chart chart
COPY app app

# Copy the git repo
#COPY .git .git

RUN CGO_ENABLED=0 GOOS=linux go build -o /server

# FROM scratch
# WORKDIR /app
EXPOSE 50051

# Import from builder.
#  COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
#  COPY --from=builder /app/bin/server /app/server
#  COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
#  COPY --from=builder /etc/passwd /etc/passwd

# Use an unprivileged user.
#USER appuser

CMD ["/server"]