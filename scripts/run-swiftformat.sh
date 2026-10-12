#!/bin/sh
# Xcode build phases don't inherit the interactive shell's PATH, so look in
# the common Homebrew locations explicitly.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

if ! command -v swiftformat >/dev/null 2>&1; then
    echo "warning: swiftformat not installed, skipping (brew install swiftformat)"
    exit 0
fi

cd "$SRCROOT" || exit 1
swiftformat --lint .
