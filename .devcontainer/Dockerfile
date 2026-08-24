FROM mcr.microsoft.com/devcontainers/python:3.14-trixie

# Custom certificate support
COPY ./certs /usr/local/share/ca-certificates/custom/
RUN find /usr/local/share/ca-certificates/custom -type f ! -name '*.crt' -delete \
    && if find /usr/local/share/ca-certificates/custom -type f -name '*.crt' -print -quit | grep -q .; then \
        update-ca-certificates; \
    fi
