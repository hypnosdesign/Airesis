FROM ruby:3.4.4

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq-dev \
    imagemagick \
    libmagickwand-dev \
    wkhtmltopdf \
    python3 \
    python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

# Node.js 18.x LTS
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Yarn
RUN npm install -g yarn

# Bundler
RUN gem install bundler -v 2.5.23

WORKDIR /usr/src/app

EXPOSE 3000

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install -j4

COPY package.json yarn.lock ./
RUN yarn install
