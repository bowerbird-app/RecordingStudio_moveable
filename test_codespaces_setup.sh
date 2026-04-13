#!/bin/bash

# This script documents the commands that are run in Codespaces.
# The real implementation lives in .devcontainer/post-create.sh.

set -e

echo "=== Simulating Codespaces postCreateCommand ==="
echo

echo "Step 1: Git LFS install"
echo "Command: git lfs install"
echo

echo "Step 2: Install Playwright"
echo "Command: npm install -g playwright"
echo "Command: playwright install --with-deps"
echo

echo "Step 3: Configure Bundler for the workspace"
echo "Command: bundle config set --local path '/usr/local/bundle'"
echo

echo "Step 4: Bundle install (workspace)"
echo "Command: bundle check || bundle install"
echo

echo "Step 5: Configure Bundler for the dummy app"
echo "Command: cd test/dummy && bundle config set --local path '/usr/local/bundle'"
echo

echo "Step 6: Bundle install (dummy app)"
echo "Command: bundle check || bundle install"
echo

echo "Step 7: Prepare database and seed demo data"
echo "Command: bin/rails db:prepare db:seed"
echo "Note: Requires PostgreSQL to be running"
echo

echo "Step 8: Build Tailwind CSS"
echo "Command: bin/rails tailwindcss:build"
echo

echo "=== Codespaces postCreateCommand complete ==="
echo
echo "To start the server:"
echo "  cd test/dummy"
echo "  bin/dev"
echo
echo "Then visit: http://localhost:3000/users/sign_in"
