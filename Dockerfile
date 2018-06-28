FROM golang:1.10 AS builder

ADD https://github.com/golang/dep/releases/download/v0.4.1/dep-linux-amd64 /usr/bin/dep
RUN chmod +x /usr/bin/dep

RUN go get github.com/karalabe/xgo

WORKDIR $GOPATH/src/github.com/gladiusio/gladius-controld
COPY Gopkg.toml Gopkg.lock ./
COPY . ./
RUN make dependencies
RUN make docker

ENV GLADIUSBASE=/gladius
RUN mkdir -p ${GLADIUSBASE}/wallet
RUN mkdir -p ${GLADIUSBASE}/keys
RUN touch ${GLADIUSBASE}/gladius-controld.toml

########################################

# Make the minimal container to distribute with only the controld and needed files
FROM scratch
ENV GLADIUSBASE=/gladius
COPY --from=builder ${GLADIUSBASE}/wallet ${GLADIUSBASE}/wallet
COPY --from=builder ${GLADIUSBASE}/keys ${GLADIUSBASE}/keys
COPY --from=builder ${GLADIUSBASE}/gladius-controld.toml ${GLADIUSBASE}/gladius-controld.toml

VOLUME ${GLADIUSBASE}/wallet
VOLUME ${GLADIUSBASE}/keys

COPY --from=builder /gladius-controld ./
ENTRYPOINT ["./gladius-controld"]