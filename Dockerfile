FROM karalabe/xgo-latest AS builder

ADD https://github.com/golang/dep/releases/download/v0.4.1/dep-linux-amd64 /usr/bin/dep
RUN chmod +x /usr/bin/dep

WORKDIR $GOPATH/src/github.com/gladiusio/gladius-controld
COPY . ./
RUN make dependencies
RUN make docker

ENV GLADIUSBASE=/gladius
RUN mkdir -p ${GLADIUSBASE}/wallet
RUN mkdir -p ${GLADIUSBASE}/keys
RUN touch ${GLADIUSBASE}/gladius-controld.toml

########################################

# Make the minimal container to distribute with only the controld and needed files
FROM ubuntu

COPY --from=builder /gladius/wallet /gladius/wallet
COPY --from=builder /gladius/keys /gladius/keys
COPY --from=builder /gladius/gladius-controld.toml /gladius/gladius-controld.toml

VOLUME /gladius/wallet
VOLUME /gladius/keys

COPY --from=builder /gladius-controld ./
ENTRYPOINT ["./gladius-controld"]