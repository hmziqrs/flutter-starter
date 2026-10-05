# Thin delegation shim over the canonical `justfile` recipes.
#
# `just` remains the documented entrypoint (see AGENTS.md); these targets exist
# so allowlisted CI/automation tooling that can only invoke `make` runs the
# exact same mise-pinned Flutter toolchain. Every target delegates; no logic
# lives here. All Flutter/Dart commands go through mise so the SDK pinned in
# mise.toml (3.44.7) is always used.

FLUTTER := mise exec -- flutter
DART := mise exec -- dart
TEST_FILES := $(shell find test -type f -name '*_test.dart' ! -path 'test/goldens/*')

# Strict analysis gate (--fatal-infos: infos fail).
analyze:
	$(FLUTTER) analyze --fatal-infos

# Formatting gate (pre-commit parity with `just format-check`).
format-check:
	$(DART) format --output=none --set-exit-if-changed lib test integration_test

# Full non-golden unit + widget suite.
test:
	$(FLUTTER) test $(TEST_FILES)

# One test file: make test-file FILE=test/features/settings/settings_page_test.dart
test-file:
	$(FLUTTER) test $(FILE)

# Dart<->Hono live-server e2e suite (self-hosts tools/hono_server).
e2e:
	$(FLUTTER) test test/e2e

# TypeScript contract tests for the in-repo test server.
server-test:
	cd tools/hono_server && bun test

.PHONY: analyze format-check test test-file e2e server-test
