#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_COMPOSER="${INSTALL_COMPOSER:-no-dev}"
NPM_RUN_BUILD="${NPM_RUN_BUILD:-false}"
ARCHIVE_NAME="${ARCHIVE_NAME:-$(basename "$PWD")}"
VERSION="${VERSION:-}"
DIST_ARCHIVE_COMMAND_VERSION="${DIST_ARCHIVE_COMMAND_VERSION:-v3.1.0}"

tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

install_file() {
  local source_path="$1"
  local destination_path="$2"

  if [ "$(id -u)" -eq 0 ]; then
    install -m 755 "$source_path" "$destination_path"
  else
    sudo install -m 755 "$source_path" "$destination_path"
  fi
}

update_version_header() {
  local file="$1"
  local version="$2"
  # Replace only the first "Version:" header line, preserving indentation and label.
  sed -i -E "0,/^[[:space:]]*\*?[[:space:]]*[Vv]ersion:/{s/^([[:space:]]*\*?[[:space:]]*[Vv]ersion:[[:space:]]*).+$/\1${version}/}" "$file"
}

bump_version() {
  local version="${1#v}" # strip a leading "v" (v1.2.3 -> 1.2.3)
  echo "🔖 Stamping version ${version}"
  local touched=0

  # Plugin: root-level PHP file carrying the "Plugin Name:" header
  local plugin_file
  plugin_file="$(grep -ilE '^[[:space:]]*\*?[[:space:]]*Plugin Name:' ./*.php 2>/dev/null | head -n1 || true)"
  if [ -n "$plugin_file" ]; then
    update_version_header "$plugin_file" "$version"
    echo "  ↳ ${plugin_file}"
    touched=1
  fi

  # Theme: style.css carrying the "Theme Name:" header
  if [ -f style.css ] && grep -qiE '^[[:space:]]*Theme Name:' style.css; then
    update_version_header style.css "$version"
    echo "  ↳ style.css"
    touched=1
  fi

  # readme.txt "Stable tag:"
  if [ -f readme.txt ]; then
    sed -i -E "0,/^[Ss]table tag:/{s/^([Ss]table tag:[[:space:]]*).+$/\1${version}/}" readme.txt
    echo "  ↳ readme.txt (Stable tag)"
  fi

  # package.json version (no git commit/tag)
  if [ -f package.json ]; then
    if npm version "$version" --no-git-tag-version --allow-same-version >/dev/null 2>&1; then
      echo "  ↳ package.json"
    else
      echo "  ⚠️ Skipped package.json ('${version}' is not valid semver)"
    fi
  fi

  [ "$touched" -eq 1 ] || echo "  ⚠️ No plugin/theme header found to update"
}

# Install WP-CLI
echo '🛠️ Set up WP-CLI'
wget --tries=3 --timeout=30 -O "$tmp_dir/wp-cli.phar" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php "$tmp_dir/wp-cli.phar" --info
install_file "$tmp_dir/wp-cli.phar" /usr/local/bin/wp
echo '✅ Successfully installed WP-CLI'

# Install dist-archive command
echo '🛠️ Set up dist-archive-command'
git config --global url."https://github.com/".insteadOf "git@github.com:"
git config --global url."https://github.com/".insteadOf "ssh://git@github.com/"
dist_archive_command_zip="$tmp_dir/dist-archive-command.zip"
wget --tries=3 --timeout=30 -O "$dist_archive_command_zip" "https://github.com/wp-cli/dist-archive-command/archive/refs/tags/${DIST_ARCHIVE_COMMAND_VERSION}.zip"
wp package install "$dist_archive_command_zip" --allow-root
echo '✅ Successfully installed dist-archive-command'

# Install Composer if requested
if [ "$INSTALL_COMPOSER" = "true" ] || [ "$INSTALL_COMPOSER" = "no-dev" ]; then
  if ! command -v composer >/dev/null 2>&1; then
    echo "🛠️ Set up composer"
    php -r "copy('https://getcomposer.org/installer', '${tmp_dir}/composer-setup.php');"
    php "$tmp_dir/composer-setup.php" --install-dir="$tmp_dir" --filename=composer
    install_file "$tmp_dir/composer" /usr/local/bin/composer
    echo '✅ Successfully installed Composer'
  fi

  # Install Composer dependencies if composer.json exists
  if [ -f "composer.json" ]; then
    echo "📦 Install Composer dependencies"
    if [ "$INSTALL_COMPOSER" = "no-dev" ]; then
      composer install --no-dev --no-interaction --prefer-dist
      echo '✅ Successfully installed Composer dependencies (no dev)'
    else
      composer install --no-interaction --prefer-dist
      echo '✅ Successfully installed Composer dependencies'
    fi
  fi
fi

# Stamp the version into plugin/theme files before building
if [ -n "$VERSION" ]; then
  bump_version "$VERSION"
fi

# Run npm build if requested
if [ "$NPM_RUN_BUILD" = "true" ] && [ -f "package.json" ]; then
  echo "📦 Install npm dependencies"
  if [ -f "package-lock.json" ]; then
    npm ci
  else
    npm install
  fi
  echo '✅ Successfully installed npm packages'
  echo "✨Running npm build..."
  npm run build
  echo '✅ Successfully run npm build'
fi

# Generate WordPress Archive
echo '🏗️ Generate archive file✨'
wp dist-archive . ./"${ARCHIVE_NAME}.zip" --allow-root
echo '🎉 Successfully generated archive file'
