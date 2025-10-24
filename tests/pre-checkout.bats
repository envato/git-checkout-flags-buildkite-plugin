#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

# export GIT_CHECKOUT_FLAGS_PLUGIN_DIR="$PWD"

@test "Sets BUILDKITE_GIT_CLONE_FLAGS when clone property is provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE="--depth=1"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_CLONE_FLAGS"

  assert_success
  assert_output "--depth=1"
}

@test "Sets BUILDKITE_GIT_FETCH_FLAGS when fetch property is provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH="--prune"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_FETCH_FLAGS"

  assert_success
  assert_output "--prune"
}

@test "Sets BUILDKITE_GIT_CLEAN_FLAGS when clean property is provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN="-ffdx"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_CLEAN_FLAGS"

  assert_success
  assert_output "-ffdx"
}

@test "Sets all flags when all properties are provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE="--depth=1"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH="--prune"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN="-ffdx"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_CLONE_FLAGS && echo \$BUILDKITE_GIT_FETCH_FLAGS && echo \$BUILDKITE_GIT_CLEAN_FLAGS"

  assert_success
  assert_line --index 0 "--depth=1"
  assert_line --index 1 "--prune"
  assert_line --index 2 "-ffdx"
}

@test "Does not set flags when no properties are provided" {
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN

  run "$PWD/hooks/pre-checkout"

  assert_success
  refute_output --partial "Setting BUILDKITE_GIT_CLONE_FLAGS"
  refute_output --partial "Setting BUILDKITE_GIT_FETCH_FLAGS"
  refute_output --partial "Setting BUILDKITE_GIT_CLEAN_FLAGS"
}

@test "Handles empty string values gracefully" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE=""
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH=""
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN=""

  run "$PWD/hooks/pre-checkout"

  assert_success
  refute_output --partial "Setting BUILDKITE_GIT_CLONE_FLAGS"
  refute_output --partial "Setting BUILDKITE_GIT_FETCH_FLAGS"
  refute_output --partial "Setting BUILDKITE_GIT_CLEAN_FLAGS"
}

@test "Applies shallow preset" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="shallow"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_CLONE_FLAGS && echo \$BUILDKITE_GIT_FETCH_FLAGS"

  assert_success
  assert_line --index 0 "-v --single-branch --depth=1 --filter=blob:none"
  assert_line --index 1 "-v --no-tags --prune --depth=1"
}

@test "Fails with unknown preset" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="unknown"

  run bash -c "source '$PWD/hooks/pre-checkout' 2>&1"

  assert_failure
  assert_output --partial "Unknown preset: unknown"
}

@test "Explicit clone flag overrides preset" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="shallow"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE="--depth=5"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_CLONE_FLAGS && echo \$BUILDKITE_GIT_FETCH_FLAGS"

  assert_success
  assert_line --index 0 "--depth=5"
  assert_line --index 1 "-v --no-tags --prune --depth=1"
}

@test "Explicit fetch flag overrides preset" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="shallow"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH="--tags"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_CLONE_FLAGS && echo \$BUILDKITE_GIT_FETCH_FLAGS"

  assert_success
  assert_line --index 0 "-v --single-branch --depth=1 --filter=blob:none"
  assert_line --index 1 "--tags"
}

@test "Preset with explicit clean flag" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="shallow"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN="-ffdx"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_CLONE_FLAGS && echo \$BUILDKITE_GIT_FETCH_FLAGS && echo \$BUILDKITE_GIT_CLEAN_FLAGS"

  assert_success
  assert_line --index 0 "-v --single-branch --depth=1 --filter=blob:none"
  assert_line --index 1 "-v --no-tags --prune --depth=1"
  assert_line --index 2 "-ffdx"
}

@test "Applies unshallow preset when repo is shallow (fallback detection)" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="unshallow"

  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.git"
  touch "$tmpdir/.git/shallow"
  cat > "$tmpdir/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "rev-parse" ]]; then
  if [[ "$2" == "--git-dir" ]]; then
    echo ".git"
    exit 0
  elif [[ "$2" == "--is-shallow-repository" ]]; then
    exit 1
  fi
fi
exit 0
EOF
  chmod +x "$tmpdir/git"

  run bash -c "cd '$tmpdir' && unset BUILDKITE_GIT_FETCH_FLAGS && PATH='$tmpdir':\$PATH source '$PWD/hooks/pre-checkout' > /dev/null && echo \${BUILDKITE_GIT_FETCH_FLAGS}"

  rm -rf "$tmpdir"

  assert_success
  assert_output "-v --prune --unshallow"
}

@test "Applies unshallow preset when repo is not shallow (fallback detection)" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="unshallow"

  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.git"

  run bash -c "cd '$tmpdir' && PATH=/tmp:\$PATH source '$PWD/hooks/pre-checkout' > /dev/null && echo \${BUILDKITE_GIT_FETCH_FLAGS:-}"

  rm -rf "$tmpdir"

  assert_success
  assert_output ""
}

@test "Applies unshallow preset when not in a git repo" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="unshallow"

  tmpdir=$(mktemp -d)

  run bash -c "cd '$tmpdir' && source '$PWD/hooks/pre-checkout' > /dev/null && echo \${BUILDKITE_GIT_FETCH_FLAGS:-}"

  rm -rf "$tmpdir"

  assert_success
  assert_output ""
}

@test "Explicit fetch flag overrides unshallow preset" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="unshallow"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH="--depth=10"

  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.git"
  touch "$tmpdir/.git/shallow"

  run bash -c "cd '$tmpdir' && PATH=/tmp:\$PATH source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_FETCH_FLAGS"

  rm -rf "$tmpdir"

  assert_success
  assert_output "--depth=10"
}
