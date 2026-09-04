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

  run bash -c "export BUILDKITE_BUILD_CHECKOUT_PATH='$tmpdir' && unset BUILDKITE_GIT_FETCH_FLAGS && PATH='$tmpdir':\$PATH source '$PWD/hooks/pre-checkout' > /dev/null && echo \${BUILDKITE_GIT_FETCH_FLAGS}"

  rm -rf "$tmpdir"

  assert_success
  assert_output "-v --prune --unshallow"
}

@test "Applies unshallow preset when repo is not shallow (fallback detection)" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="unshallow"

  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.git"

  run bash -c "export BUILDKITE_BUILD_CHECKOUT_PATH='$tmpdir' && PATH=/tmp:\$PATH source '$PWD/hooks/pre-checkout' > /dev/null && echo \${BUILDKITE_GIT_FETCH_FLAGS:-}"

  rm -rf "$tmpdir"

  assert_success
  assert_output ""
}

@test "Applies unshallow preset when not in a git repo" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="unshallow"

  tmpdir=$(mktemp -d)

  run bash -c "export BUILDKITE_BUILD_CHECKOUT_PATH='$tmpdir' && source '$PWD/hooks/pre-checkout' > /dev/null && echo \${BUILDKITE_GIT_FETCH_FLAGS:-}"

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

  run bash -c "export BUILDKITE_BUILD_CHECKOUT_PATH='$tmpdir' && PATH=/tmp:\$PATH source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_GIT_FETCH_FLAGS"

  rm -rf "$tmpdir"

  assert_success
  assert_output "--depth=10"
}

@test "Clears BUILDKITE_REPO when skip is true" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP="true"
  export BUILDKITE_REPO="git@github.com:envato/example.git"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \"[\$BUILDKITE_REPO]\""

  assert_success
  assert_output "[]"
}

@test "Announces that the checkout is skipped" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP="true"

  run "$PWD/hooks/pre-checkout"

  assert_success
  assert_output --partial "Skipping the checkout"
}

@test "Accepts on and 1 as skip values" {
  export BUILDKITE_REPO="git@github.com:envato/example.git"

  for value in on 1; do
    run bash -c "export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP='$value' && source '$PWD/hooks/pre-checkout' > /dev/null && echo \"[\$BUILDKITE_REPO]\""

    assert_success
    assert_output "[]"
  done
}

@test "Leaves BUILDKITE_REPO alone when skip is false" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP="false"
  export BUILDKITE_REPO="git@github.com:envato/example.git"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_REPO"

  assert_success
  assert_output "git@github.com:envato/example.git"
}

@test "Leaves BUILDKITE_REPO alone when skip is not provided" {
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP
  export BUILDKITE_REPO="git@github.com:envato/example.git"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \$BUILDKITE_REPO"

  assert_success
  assert_output "git@github.com:envato/example.git"
}

@test "Skip takes precedence over the other options" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP="true"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET="shallow"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE="--depth=5"
  export BUILDKITE_REPO="git@github.com:envato/example.git"

  run bash -c "source '$PWD/hooks/pre-checkout' > /dev/null && echo \"[\$BUILDKITE_REPO]\" && echo \"[\${BUILDKITE_GIT_CLONE_FLAGS:-}]\""

  assert_success
  assert_line --index 0 "[]"
  assert_line --index 1 "[]"
}

@test "Warns that the other options are ignored when skipping" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP="true"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE="--depth=5"

  run "$PWD/hooks/pre-checkout"

  assert_success
  assert_output --partial "Ignoring the other options"
}

@test "Does not warn about other options when none are set" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_SKIP="true"
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_PRESET
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH
  unset BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN

  run "$PWD/hooks/pre-checkout"

  assert_success
  refute_output --partial "Ignoring the other options"
}
