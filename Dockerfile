# syntax=docker/dockerfile:1

# =============================================================================
#  SarahUB — container image (CUDA / GPU variant)
# =============================================================================

ARG BASE_IMAGE=nvidia/cuda:12.5.1-cudnn-devel-ubuntu22.04
FROM ${BASE_IMAGE}

# -----------------------------------------------------------------------------
# Build-time tunables
# -----------------------------------------------------------------------------
ARG TZ=Asia/Kolkata
ARG APP_USER=sarah
ARG APP_HOME=/sarah
ARG MINICONDA_DIR=${APP_HOME}/miniconda
ARG CONDA_ENV=py311
ARG PYTHON_VERSION=3.11
ARG NODE_URL=https://deb.nodesource.com/setup_current.x
ARG MINIFORGE_URL=https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
ARG REPO_OWNER=Mahesh953-hub
ARG REPO_NAME=SarahUB
ARG REPO_BRANCH=main
ARG EXPOSE_PORT=7860

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=${TZ} \
    CONDA_AUTO_UPDATE_CONDA=false \
    PYTHONUNBUFFERED=1

RUN export TZ=${TZ}

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        sudo \
        git \
        wget \
        zip \
        unzip \
        neofetch \
        gnupg2 \
        libnss3 \
        libx11-xcb1 \
        libxcursor1 \
        libxi6 \
        libgtk-3-0 \
        libnspr4 \
        libdbus-1-3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libgl1-mesa-glx \
        libcups2 \
        libdrm2 \
        libxkbcommon0 \
        libatspi2.0-0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libgbm1 \
        libasound2 \
        gosu \
        p7zip-full \
        mediainfo \
        procps \
        htop \
        vim \
        nano \
        bzip2 \
        build-essential \
        libsndfile-dev \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Node.js — builds the web setup server's frontend
# -----------------------------------------------------------------------------
RUN curl -fsSL ${NODE_URL} | bash - \
    && apt-get install -y nodejs

# -----------------------------------------------------------------------------
# Non-root runtime user
# -----------------------------------------------------------------------------
RUN useradd -m -s /bin/bash ${APP_USER} \
    && echo "${APP_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-${APP_USER}

USER ${APP_USER}
ENV HOME=${APP_HOME}
WORKDIR ${APP_HOME}

# -----------------------------------------------------------------------------
# Miniforge (conda + mamba, conda-forge) + Python environment
# -----------------------------------------------------------------------------
ENV PATH=${MINICONDA_DIR}/bin:$PATH

RUN curl -sL -o ${APP_HOME}/miniforge.sh ${MINIFORGE_URL} \
    && bash ${APP_HOME}/miniforge.sh -b -p ${MINICONDA_DIR} \
    && rm ${APP_HOME}/miniforge.sh \
    && ${MINICONDA_DIR}/bin/mamba create -y -n ${CONDA_ENV} python=${PYTHON_VERSION} \
    && ${MINICONDA_DIR}/bin/mamba clean -afy

ENV PATH=${MINICONDA_DIR}/envs/${CONDA_ENV}/bin:${MINICONDA_DIR}/bin:$PATH

# -----------------------------------------------------------------------------
# Application source — securely cloned using BuildKit secrets
# -----------------------------------------------------------------------------
RUN echo "Better logs#2"

RUN --mount=type=secret,id=GIT_TOKEN,required=false \
    if [ -f /run/secrets/GIT_TOKEN ]; then \
        TOKEN=$(cat /run/secrets/GIT_TOKEN); \
        GIT_URL="https://${TOKEN}@github.com/${REPO_OWNER}/${REPO_NAME}.git"; \
    else \
        GIT_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"; \
    fi \
    && git clone --branch "${REPO_BRANCH}" --single-branch "${GIT_URL}" "${APP_HOME}/${REPO_NAME}"

WORKDIR ${APP_HOME}/${REPO_NAME}

RUN ls -all

# -----------------------------------------------------------------------------
# Python dependencies
# -----------------------------------------------------------------------------
RUN echo "I want rebuild!!!!"

RUN pip install --no-cache-dir -U pip \
    && pip install --no-cache-dir requests dnspython redis pymongo psycopg2-binary \
    && pip install --no-cache-dir fastapi uvicorn nest-asyncio \
    && pip install --no-cache-dir -r requirements.txt

RUN pip install --no-cache-dir -r res*/st*/op* || true

# -----------------------------------------------------------------------------
# FFmpeg — pulled from a prebuilt static image
# -----------------------------------------------------------------------------
USER root
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /ffprobe /usr/local/bin/

# -----------------------------------------------------------------------------
# Permissions + final runtime user
# -----------------------------------------------------------------------------
RUN chown -R ${APP_USER}:${APP_USER} ${APP_HOME} \
    && chmod -R 755 ${APP_HOME} \
    && chmod +x ${APP_HOME}/${REPO_NAME}/start.sh

USER ${APP_USER}
WORKDIR ${APP_HOME}/${REPO_NAME}

EXPOSE ${EXPOSE_PORT}

CMD ["./start.sh"]
