# Changelog

All notable changes to this project will be documented in this file, per [the Keep a Changelog standard](http://keepachangelog.com/).

## [0.3.0] - 2026-07-06

- Feature: Add `version` input to stamp the plugin/theme header, `readme.txt` Stable tag and `package.json` version from the release tag before building

## [0.2.0] - 2026-05-21

- Feature: Bump all Github Actions
- Feature: Add automated test
- Fix: Use correct action name for usage example
- Fix: Harden build script runtime installs and pin dist-archive-command
- Fix: Use non-interactive Composer installs and npm ci when package-lock.json exists

## [0.1.3] - 2025-08-25

- Feature: Add no-dev flag to exclude Composer dev dependencies

## [0.1.2] - 2025-04-08

- Fix: downgrade upload-artifact action to version v3

## [0.1.1] - 2025-04-07

- Fix: Bump Github Actions & default NODE versions
- Feature: Add flag to opt-out for artifact upload
- Update README.md

## [0.1.0] - 2024-08-30

- Initial release.
