# Build Image
#  $ docker build -t clivern/prober:0.11.2 .
#
# Run Probe
#
#  $ docker run -d --rm \
#     --network host \
#     -v $PWD/cloudprober.cfg:/etc/cloudprober.cfg \
#     --name prober \
#     clivern/prober:0.11.2
#
#  http://127.0.0.1:9313/metrics
#  http://127.0.0.1:9313/status

FROM golang:1.18.4 as builder

ENV GO111MODULE=on

ARG CLOUD_PROBER_VERSION=v0.11.2

RUN mkdir -p $GOPATH/src/github.com/google

RUN git clone -b master https://github.com/google/cloudprober.git $GOPATH/src/github.com/google/cloudprober

WORKDIR $GOPATH/src/github.com/google/cloudprober

RUN git checkout tags/$CLOUD_PROBER_VERSION

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -o cloudprober -ldflags "-X main.version=$CLOUD_PROBER_VERSION -extldflags -static" ./cmd/cloudprober.go

RUN ./cloudprober -version

FROM alpine:3.16.0

RUN mkdir -p /app/bin

COPY --from=builder /go/src/github.com/google/cloudprober/cloudprober /app/bin/cloudprober

WORKDIR /app/bin

RUN ./cloudprober -version

CMD ["./cloudprober", "--logtostderr"]
