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
GOBUILD=go build -a
GOTEST=go test

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
	docker build --tag gladiusio:gladius-controld .

docker: test
	$(GOBUILD) -o /gladius-controld $(CTL_SRC)
