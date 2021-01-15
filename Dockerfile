# Build the manager binary
FROM golang:1.15.6-alpine3.12 as builder

RUN apk add --update --no-cache git bash
WORKDIR /workspace
# Copy the jsonnet source
COPY . operator/
COPY ./jsonnet/vendor/github.com/observatorium/deployments/components/ components/

# Build
COPY .bingo /workspace/.bingo
RUN GO111MODULE="on" cd /workspace/.bingo && go build -mod=mod -modfile=locutus.mod -o=/workspace/locutus "github.com/brancz/locutus"

FROM alpine:3.12 as runner

WORKDIR /
COPY --from=builder /workspace/locutus /
COPY --from=builder /workspace/operator/jsonnet /environments/operator
COPY --from=builder /workspace/components/ /components/
COPY --from=builder /workspace/operator/jsonnet/vendor/ /vendor/

RUN chgrp -R 0 /vendor && chmod -R g=u /vendor
RUN chgrp -R 0 /components && chmod -R g=u /components

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ARG DOCKERFILE_PATH
ARG VCS_BRANCH

LABEL vendor="Observatorium" \
    name="observatorium/operator" \
    description="Observatorium Operator" \
    io.k8s.display-name="observatorium/operator" \
    io.k8s.description="Observatorium Operator" \
    maintainer="Observatorium <team-monitoring@redhat.com>" \
    version="$VERSION" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.description="Observatorium Operator" \
    org.label-schema.docker.cmd="docker run --rm observatorium/operator" \
    org.label-schema.docker.dockerfile=$DOCKERFILE_PATH \
    org.label-schema.name="observatorium/operator" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-branch=$VCS_BRANCH \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/observatorium/operator" \
    org.label-schema.vendor="observatorium/operator" \
    org.label-schema.version=$VERSION

ENTRYPOINT ["/locutus", "--renderer=jsonnet", "--renderer.jsonnet.entrypoint=environments/operator/main.jsonnet", "--trigger=resource", "--trigger.resource.config=environments/operator/config.yaml"]
