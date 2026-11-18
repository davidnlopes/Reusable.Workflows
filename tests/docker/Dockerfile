FROM busybox:1.37
ARG VERSION=dev
RUN echo "$VERSION" > /version && uname -m >> /version
USER 65534
HEALTHCHECK NONE
CMD ["cat", "/version"]
