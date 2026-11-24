PREFIX ?= $(HOME)/.local

build:
	go build -o build/nothin ./cmd/nothin

test:
	go test ./...
	/usr/lib/qt6/bin/qmltestrunner -input shell/

install: build
	install -Dm755 build/nothin $(PREFIX)/bin/nothin

.PHONY: build test install
