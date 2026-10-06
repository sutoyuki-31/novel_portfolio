# syntax = docker/dockerfile:1

# 本番用Dockerfile。ビルドと実行の例:
# docker build -t my-app .
# docker run -d -p 3000:3000 -v rails_storage:/rails/storage \
#   -e RAILS_MASTER_KEY=<config/master.key の値> --name my-app my-app

# .ruby-version と必ず一致させること
ARG RUBY_VERSION=4.0.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# 実行時に必要なパッケージ
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"


# ---- ビルド用ステージ(最終イメージには含まれない) ----
FROM base AS build

# gemのビルドとアセットのビルドに必要なパッケージ
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config nodejs npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    npm install -g yarn

# gem(Gemfileが変わらない限りキャッシュが効く)
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# JSパッケージ(importmapを使っている場合は、この2行とyarn関連をすべて削除)
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# アプリ本体
COPY . .

# bootsnapのプリコンパイルと、binファイルの実行権限・改行コード修正
RUN bundle exec bootsnap precompile app/ lib/ && \
    chmod +x bin/* && \
    sed -i "s/\r$//g" bin/* && \
    sed -i 's/ruby\.exe$/ruby/' bin/*

# RAILS_MASTER_KEY なしでアセットをプリコンパイル
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# ---- 最終ステージ ----
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# 非rootユーザーで実行(書き込みが必要なディレクトリだけ所有権を付与)
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# SQLiteや添付ファイルを永続化したい場合は storage をボリュームにする
VOLUME /rails/storage

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]