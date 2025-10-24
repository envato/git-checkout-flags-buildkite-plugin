# Git Checkout Flags Buildkite Plugin

A minimal [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that allows you to control git clone, fetch, and clean flags during checkout.

## Example

Using a preset:

```yaml
steps:
  - command: make test
    plugins:
      - envato/git-checkout-flags#v1.0.0:
          preset: shallow
```

Using custom flags:

```yaml
steps:
  - command: make test
    plugins:
      - envato/git-checkout-flags#v1.0.0:
          clone: "<clone-flags>"
          fetch: "<fetch-flags>"
```

## Configuration

### `preset` (optional, string)

Use a predefined set of flags. Available presets:

- `shallow`: Optimized for fast, shallow clones with minimal history
  - Clone flags: `-v --single-branch --depth=1 --filter=blob:none`
  - Fetch flags: `-v --no-tags --prune --depth=1`

Explicit `clone`, `fetch`, or `clean` options will override preset values.

### `clone` (optional, string)

Flags to pass to `git clone`. Sets `BUILDKITE_GIT_CLONE_FLAGS`.

### `fetch` (optional, string)

Flags to pass to `git fetch`. Sets `BUILDKITE_GIT_FETCH_FLAGS`.

### `clean` (optional, string)

Flags to pass to `git clean`. Sets `BUILDKITE_GIT_CLEAN_FLAGS`.

## Developing

To run the tests:

```bash
make test
```

To run linting:

```bash
make lint
```

## License

MIT (see [LICENSE](LICENSE))
