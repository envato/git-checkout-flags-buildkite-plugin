# Git Checkout Flags Buildkite Plugin

A minimal [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that allows you to control git clone, fetch, and clean flags during checkout.

## Example

```yaml
steps:
  - command: make test
    plugins:
      - envato/git-checkout-flags#v1.0.0:
          clone: "--depth=1 --no-tags"
          fetch: "--prune"
          clean: "-ffdx"
```

## Configuration

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
