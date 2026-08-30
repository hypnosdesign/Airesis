FROM ruby:4.0.6-bookworm

ARG NODE_VERSION=24.20.0
ARG YARN_VERSION=4.18.0

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    chromium \
    chromium-driver \
    curl \
    git \
    libpq-dev \
    imagemagick \
    libmagickwand-dev \
    wkhtmltopdf \
    python3 \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

ENV CHROME_BIN=/usr/bin/chromium \
    SE_CHROMEDRIVER=/usr/bin/chromedriver

# Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y "nodejs=${NODE_VERSION}-1nodesource1" \
    && rm -rf /var/lib/apt/lists/*

# Yarn
RUN corepack enable \
    && corepack install --global "yarn@${YARN_VERSION}" \
    && yarn --version

# Bundler
RUN gem install bundler -v 4.0.19

WORKDIR /usr/src/app

EXPOSE 3000

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install -j4

COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install --immutable
