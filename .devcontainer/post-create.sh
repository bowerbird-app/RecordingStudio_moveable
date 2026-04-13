#!/usr/bin/env bash

set -euo pipefail

cd /workspace

echo "== Installing Git LFS =="
git lfs install

echo "== Installing Playwright =="
npm install -g playwright
playwright install --with-deps

echo "== Installing root workspace dependencies =="
cd /workspace
bundle config set --local path /usr/local/bundle
bundle check || bundle install

echo "== Installing dummy app dependencies =="
cd /workspace/test/dummy
bundle config set --local path /usr/local/bundle
bundle check || bundle install

echo "== Preparing database and seeding demo data =="
bin/rails db:prepare db:seed

echo "== Building Tailwind CSS =="
bin/rails tailwindcss:build
