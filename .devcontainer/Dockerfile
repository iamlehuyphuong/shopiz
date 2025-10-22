# The below image is created out of the Dockerfile.base
# It has the dependencies already installed so that codespace will boot up fast
FROM ghcr.io/chatwoot/chatwoot_codespace:latest

USER root
# Do the set up required for chatwoot app
WORKDIR /workspace

# Copy dependency files first for better caching
COPY package.json pnpm-lock.yaml ./
COPY Gemfile Gemfile.lock ./

RUN apt-get update && apt-get install -y --no-install-recommends \
    poppler-utils \
    tesseract-ocr \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install dependencies (will be cached if files don't change)
#RUN pnpm store prune && pnpm install --force
RUN gem install bundler
RUN bundle install

# Copy source code after dependencies are installed
COPY . /workspace
