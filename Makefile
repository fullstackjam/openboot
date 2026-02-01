.PHONY: build build-all clean test run

BINARY_NAME=openboot
VERSION=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

build:
	go build -ldflags="-s -w -X main.version=$(VERSION)" -o $(BINARY_NAME) ./cmd/openboot

build-all:
	GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o $(BINARY_NAME)-darwin-arm64 ./cmd/openboot
	GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o $(BINARY_NAME)-darwin-amd64 ./cmd/openboot
	GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o $(BINARY_NAME)-linux-arm64 ./cmd/openboot
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o $(BINARY_NAME)-linux-amd64 ./cmd/openboot

clean:
	rm -f $(BINARY_NAME) $(BINARY_NAME)-*

test:
	go test ./...

run:
	go run ./cmd/openboot

run-dry:
	go run ./cmd/openboot --dry-run

install:
	go install ./cmd/openboot
