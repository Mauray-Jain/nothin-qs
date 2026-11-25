PREFIX ?= $(HOME)/.local
QSB := $(or $(shell command -v qsb),$(wildcard /usr/lib/qt6/bin/qsb))

build: check-shaders
	go build -o build/nothin ./cmd/nothin

test:
	go test ./...
	/usr/lib/qt6/bin/qmltestrunner -input shell/

install: build
	install -Dm755 build/nothin $(PREFIX)/bin/nothin

shaders:
	scripts/compile-shaders.sh

# The committed .qsb files must match their sources. Skipped without qsb
# (qt6-shadertools is only needed for development).
check-shaders:
ifneq ($(QSB),)
	@mkdir -p build/qsb
	@QSB=$(QSB) scripts/compile-shaders.sh $(CURDIR)/build/qsb 2>/dev/null
	@for f in build/qsb/*.qsb; do \
		cmp -s $$f shell/shaders/$$(basename $$f) || { echo "$$(basename $$f) is stale: run make shaders"; exit 1; }; \
	done
endif

.PHONY: build test install shaders check-shaders
