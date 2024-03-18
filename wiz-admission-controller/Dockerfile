FROM gcr.io/distroless/static-debian11
ADD ./bin/linux/wiz-admission-controller /usr/bin
COPY ./internal/version/version.txt /usr/bin/wiz-admission-controller-version
ENTRYPOINT ["/usr/bin/wiz-admission-controller"]
