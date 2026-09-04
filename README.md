# Git Checkout Flags Buildkite Plugin

A minimal [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) that allows you to control git clone, fetch, and clean flags during checkout.

## Example

Using a preset:

```yaml
steps:
  - command: make test
    plugins:
      - envato/git-checkout-flags#v1.2.0:
          preset: shallow
```

Using custom flags:

```yaml
steps:
  - command: make test
    plugins:
      - envato/git-checkout-flags#v1.2.0:
          clone: "<clone-flags>"
          fetch: "<fetch-flags>"
```

Skipping the checkout on a step that never reads the codebase:

```yaml
steps:
  - command: echo "All required steps have completed"
    plugins:
      - envato/git-checkout-flags#v1.2.0:
          skip: true
```

## Configuration

### `skip` (optional, boolean)

Skip the checkout entirely. Use it on steps that never read the codebase, such
as gates that only echo a message, or steps whose whole job is done by another
plugin.

This works by clearing `BUILDKITE_REPO`. With no repository to clone, the agent
allocates a fresh temporary directory for the job, skips the checkout, and
removes the directory afterwards. Any existing checkout on the agent is left
alone, so the next job to land there still gets an incremental fetch rather
than a full clone.

The temporary directory also means the job finds no repository-local hooks.
That is the advantage over the agent's own `BUILDKITE_SKIP_CHECKOUT`, which
keeps using the agent's normal checkout directory: that directory is not
branch-scoped, so a tree left behind by an earlier job would still supply
`.buildkite/hooks`.

The other options are ignored when `skip` is set.

### `preset` (optional, string)

Use a predefined set of flags. Available presets:

- `shallow`: Optimized for fast, shallow clones with minimal history
- `unshallow`: Detects shallow repositories (from a previous job) and fetches full history

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
