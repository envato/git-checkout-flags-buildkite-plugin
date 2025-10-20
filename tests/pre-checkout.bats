#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

# export GIT_CHECKOUT_FLAGS_PLUGIN_DIR="$PWD"

@test "Sets BUILDKITE_GIT_CLONE_FLAGS when clone property is provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE="--depth=1"

  run "$PWD/hooks/pre-checkout"

  assert_success
  assert_output --partial "Setting BUILDKITE_GIT_CLONE_FLAGS to: --depth=1"
}

@test "Sets BUILDKITE_GIT_FETCH_FLAGS when fetch property is provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH="--prune"

  run "$PWD/hooks/pre-checkout"

  assert_success
  assert_output --partial "Setting BUILDKITE_GIT_FETCH_FLAGS to: --prune"
}

@test "Sets BUILDKITE_GIT_CLEAN_FLAGS when clean property is provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN="-ffdx"

  run "$PWD/hooks/pre-checkout"

  assert_success
  assert_output --partial "Setting BUILDKITE_GIT_CLEAN_FLAGS to: -ffdx"
}

@test "Sets all flags when all properties are provided" {
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLONE="--depth=1"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_FETCH="--prune"
  export BUILDKITE_PLUGIN_GIT_CHECKOUT_FLAGS_CLEAN="-ffdx"

  run "$PWD/hooks/pre-checkout"

  assert_success
  assert_output --partial "Setting BUILDKITE_GIT_CLONE_FLAGS to: --depth=1"
  assert_output --partial "Setting BUILDKITE_GIT_FETCH_FLAGS to: --prune"
  assert_output --partial "Setting BUILDKITE_GIT_CLEAN_FLAGS to: -ffdx"
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
