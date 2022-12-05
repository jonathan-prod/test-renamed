# Default value for entrypoint tag name is main
ARG ENTRYPOINT_TAG_NAME=main
FROM ghcr.io/jitsecurity-controls/jit-control-entrypoint-alpine:${ENTRYPOINT_TAG_NAME} AS entrypoint-tag
ENV SOURCE_CODE_FOLDER=../code
FROM checkmarx/kics:v1.6.0-alpine
ENV CONTROL_NAME=KICS

COPY --from=entrypoint-tag /entrypoint /opt/entrypoint
COPY ./plugins/mapping.yml /opt/plugins/mapping.yml

ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

# Copy the cloned jit-logger and jit-remediation
COPY jit-remediation/ /opt/remediate
RUN pip install /opt/remediate
COPY jit-logger/ /opt/jit-logger
RUN pip install /opt/jit-logger

COPY src /opt/src
RUN pip install -r /opt/src/requirements.txt

WORKDIR /recipes
COPY ./recipes /recipes

RUN git config --global --add safe.directory /code

WORKDIR /opt/src
ENV SOURCE_CODE_FOLDER=../code
ENTRYPOINT ["/opt/entrypoint", "python main.py"]
