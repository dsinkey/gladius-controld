##
## Makefile to test and build the gladius binaries
##

##
# GLOBAL VARIABLES
##

# if we are running on a windows machine
# we need to append a .exe to the
# compiled binary
BINARY_SUFFIX=
ifeq ($(OS),Windows_NT)
	BINARY_SUFFIX=.exe
endif

ifeq ($(GOOS),windows)
	BINARY_SUFFIX=.exe
endif

# code source and build directories
SRC_DIR=./cmd
DST_DIR=./build

CTL_SRC=$(SRC_DIR)/gladius-controld
CTL_DEST=$(DST_DIR)/gladius-controld$(BINARY_SUFFIX)

# commands for go
#GOBUILD=CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-w -extldflags "-static"'
GOBUILD=go build -a
GOTEST=go test

ifeq ($(OS),Windows_NT)
	DOCKER_OS ?= windows
	ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
		DOCKER_ARCH ?= amd64
	else
		ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
			DOCKER_ARCH ?= amd64
		endif
		ifeq ($(PROCESSOR_ARCHITECTURE),x86)
			DOCKER_ARCH ?= 386
		endif
	endif
else
	# check if we are running mac os x - by default we will use amd64 in thise case (docker for mac is a linux 64bit machine)
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
		DOCKER_OS ?= linux
		DOCKER_ARCH ?= amd64
	endif
	# if we run linux we need to check which processor arch we run on
	ifeq ($(UNAME_S),Linux)
		DOCKER_OS ?= linux
		UNAME_M := $(shell uname -m)
		ifeq ($(UNAME_M),x86_64)
			DOCKER_ARCH ?= amd64
		endif
		ifneq ($(filter %86,$(UNAME_M)),)
			DOCKER_ARCH ?= 386
		endif
		ifneq ($(filter %arm,$(UNAME_M)),)
			DOCKER_ARCH ?= arm
		endif
    endif
endif


##
# MAKE TARGETS
##

# general make targets
all: controld

clean:
	rm -rf ./build/*
	go clean

# dependency management
dependencies:
	# install go packages
	dep ensure

	# Deal with the ethereum cgo bindings
	go get github.com/ethereum/go-ethereum

	cp -r \
	"${GOPATH}/src/github.com/ethereum/go-ethereum/crypto/secp256k1/libsecp256k1" \
	"vendor/github.com/ethereum/go-ethereum/crypto/secp256k1/"

test: $(CTL_SRC)
	$(GOTEST) ./...

lint:
	gometalinter.v2 ./...

controld: test
	$(GOBUILD) -o $(CTL_DEST) $(CTL_SRC)

docker_image:
	docker build --tag gladiusio:gladius-controld \
		--build-arg gladius_os=${DOCKER_OS} \
		--build-arg gladius_architecture=${DOCKER_ARCH} \
		.

docker: test
	$(GOBUILD) -o /gladius-controld $(CTL_SRC)
