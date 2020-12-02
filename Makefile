NAME := p4-navt

#brunch name version
VERSION := $(shell git rev-parse --abbrev-ref HEAD)

PKG_NAME=$(shell basename `pwd`)

LDFLAGS := -ldflags="-s -w  -X \"github.com/takehaya/p4-navt/pkg/version.Version=$(VERSION)\" -extldflags \"-static\""
SRCS    := $(shell find . -type f -name '*.go')

P4SRC   := "switch.p4"

.DEFAULT_GOAL := build
build: $(SRCS)
	go build $(LDFLAGS) -o ./bin/$(NAME) ./cmd/$(NAME)

.PHONY: run
run:
	go run $(LDFLAGS) ./cmd/$(NAME)

## lint
.PHONY: lint
lint:
	@for pkg in $$(go list ./...): do \
		golint --set_exit_status $$pkg || exit $$?; \
	done

.PHONY: codecheck
codecheck:
	test -z "$(gofmt -s -l . | tee /dev/stderr)"
	go vet ./...

.PHONY: clean
clean:
	rm -rf bin

.PHONY: install
install:
	go install $(LDFLAGS) ./cmd/$(NAME)

.PHONY: p4
p4:
	p4c --std p4_16 -b bmv2 --p4runtime-files ./build.bmv2/$(P4SRC).p4info.txt -o build.bmv2 ./p4src/$(P4SRC)
