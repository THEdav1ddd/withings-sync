FROM python:3.12-alpine

ARG PROJECT="withings-sync"
ARG PACKAGE="withings_sync"
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apk --no-cache add supercronic

RUN if getent passwd ${USER_UID} >/dev/null; then \
    deluser $(getent passwd ${USER_UID} | cut -d: -f1); fi && \
    if getent group ${USER_GID} >/dev/null; then \
    delgroup $(getent group ${USER_GID} | cut -d: -f1); fi
RUN addgroup --system --gid ${USER_GID} ${PROJECT} && \
    adduser --system --disabled-password --home /home/${PROJECT} \
    --uid ${USER_UID} --ingroup ${PROJECT} ${PROJECT}

ENV PROJECT_DIR="/home/${PROJECT}"

USER $PROJECT
WORKDIR $PROJECT_DIR

# Install uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV PATH="${PROJECT_DIR}/.local/bin:${PATH}" \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

COPY --chown=$PROJECT:$PROJECT pyproject.toml uv.lock README.md $PROJECT_DIR/
RUN uv sync --frozen --no-dev --no-install-project

COPY --chown=$PROJECT:$PROJECT $PACKAGE ./$PACKAGE/
RUN uv sync --frozen --no-dev

ENTRYPOINT ["uv", "run", "withings-sync"]
