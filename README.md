# WordPress Build Archive GitHub Action

A GitHub Action to generate a zip archive of a WordPress project using [WP-CLI](https://developer.wordpress.org/cli/commands/dist-archive/).

### Usage Example

Place the following in `/.github/workflows/main.yml`

```yml
on: push
name: 🚀 Build WordPress Plugin on Push
jobs:
  build-deploy:
    name: 🎉 Build archive
    runs-on: ubuntu-latest
    steps:
      - name: 🚚 Checkout latest code
        uses: actions/checkout@v4

      - name: 📦 Build Plugin
        uses: webshr/action-wp-build-archive@latest
        with:
          install-composer: true # optional; defaults to no-dev
          npm-run-build: true # optional; defaults to false
          node-version: 20 # optional; defaults to 20
          retention-days: 5 # optional; defaults to 30
          archive-name: my-plugin # optional; defaults to repository-name
          upload-artifact: false # optional; defaults to false
```

## Excluding files from the archive

You can specify files or directories to be excluded from an archive using a `.distignore` or a `.gitattributes` file. It's recommended to use a `.distignore` file, especially for built files in `.gitignore`. The `.gitattributes` file is useful for projects that don't run a build step and ensures consistency with files committed to WordPress.org.

`.gitignore` example:

```.gitignore
/.wordpress-org
/.git
/node_modules

.distignore
.gitignore
```

`.gitattributes` example:

```.gitattributes
# Directories
/.github export-ignore

# Files
/.gitattributes export-ignore
/.gitignore export-ignore
```

### Configuration

Add your keys directly to your .yml configuration file or referenced from the `Secrets` project store.

It is strongly recommended to save sensive credentials as secrets.

| **Key Name**       | **Required** | **Example** | **Default**       | **Description**                                                                                                                |
| ------------------ | ------------ | ----------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `install-composer` | no           | `no-dev`    | `no-dev`          | Install Composer packages before generating archive. Use `true`, `no-dev`, or `false`                                          |
| `npm-run-build`    | no           | `true`      | `false`           | Run `npm run build` before generating archive                                                                                  |
| `node-version`     | no           | `20`        | `20`              | Node version                                                                                                                   |
| `retention-days`   | no           | `3`         | `30`              | Number of days to retain the arhive                                                                                            |
| `archive-name`     | no           | `my-plugin` | `repository-name` | Name of the zip archive                                                                                                        |
| `upload-artifact`  | no           | `true`      | `false`           | Upload the generated archive as an artifact                                                                                    |
| `version`          | no           | `1.2.3`     | `(none)`          | Version to stamp into the plugin/theme header, `readme.txt` Stable tag and `package.json` before building. Leave empty to skip |

The action installs WP-CLI and the `wp-cli/dist-archive-command` package at runtime. The dist archive command is pinned to a compatible release for reproducible builds.

### Bumping the version from the release tag

Set the `version` input to stamp a version into your project before the archive is built. When present, it updates:

- the `Version:` header of the main plugin file (or a theme's `style.css`)
- the `Stable tag:` line in `readme.txt`
- the `version` field in `package.json`

Typically you drive it from the tag that triggered the release:

```yml
on:
  push:
    tags: ["[0-9]+.[0-9]+.[0-9]+"]

jobs:
  build-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Plugin
        uses: webshr/action-wp-build-archive@latest
        with:
          npm-run-build: true
          archive-name: my-plugin
          version: ${{ github.ref_name }} # e.g. tag 1.2.3
```

The version is stamped into the files that go into the archive; it is not committed back to the repository. A leading `v` (e.g. `v1.2.3`) is stripped automatically.

### Credits

This action is inspired by and builds upon the work done in the [Generate WordPress Archive](https://github.com/rudlinkon/action-wordpress-build-zip) and [WordPress Plugin Build Zip](https://github.com/10up/action-wordpress-plugin-build-zip) Actions.

### Further Reading

- [Official WP-CLI Command documentation](https://developer.wordpress.org/cli/commands/dist-archive/) for ``wp dist-archive`

### License

This action is licensed under the MIT License.
