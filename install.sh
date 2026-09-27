#!/bin/sh

set -eu

REPO="Xoffio/dotfiles"
CHEZMOI_VERSION="2.72.2"
INSTALL_DIR="$HOME/.local/bin"

# --- detect OS ---
os=""
case "$(uname -s)" in
Linux) os="linux" ;;
Darwin) os="darwin" ;;
*)
	echo "Unsupported OS: $(uname -s)" >&2
	exit 1
	;;
esac

# --- detect architecture ---
arch=""
case "$(uname -m)" in
x86_64 | amd64) arch="amd64" ;;
aarch64 | arm64) arch="arm64" ;;
*)
	echo "Unsupported architecture: $(uname -m)" >&2
	exit 1
	;;
esac

# --- detect musl (linux only) ---
musl=""
if [ "$os" = "linux" ]; then
	musl="-musl"
fi

filename="chezmoi-${os}-${arch}${musl}"

mkdir -p "$INSTALL_DIR"
tmpdir=$(mktemp -d)
cd "$tmpdir"

echo "Downloading chezmoi v${CHEZMOI_VERSION} (${filename})..."
curl -fsSLO "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/${filename}"
curl -fsSLO "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_checksums.txt"

echo "Verifying checksum..."
if command -v sha256sum >/dev/null 2>&1; then
	grep " ${filename}\$" "chezmoi_${CHEZMOI_VERSION}_checksums.txt" | sha256sum -c -
else
	grep " ${filename}\$" "chezmoi_${CHEZMOI_VERSION}_checksums.txt" | shasum -a 256 -c -
fi

chmod +x "$filename"
mv "$filename" "$INSTALL_DIR/chezmoi"

cd "$HOME"
rm -rf "$tmpdir"

echo "chezmoi installed to $INSTALL_DIR/chezmoi"

# make it usable in this same script run, even before the user's
# shell config (which normally puts ~/.local/bin on PATH) is applied
PATH="$INSTALL_DIR:$PATH"
export PATH

if [ "$#" -gt 0 ]; then
	# Args were passed after `--`, e.g.:
	#   sh -c "$(curl -fsLS .../install.sh)" -- init --apply Xoffio
	# Forward them straight to the chezmoi binary we just installed.
	echo "Running: chezmoi $*"
	"$INSTALL_DIR/chezmoi" "$@"
# else
#   # No args given, default to this repo.
#   echo "Applying dotfiles from ${REPO}..."
#   "$INSTALL_DIR/chezmoi" init --apply "https://github.com/${REPO}.git"
fi

echo "Done. Start a new shell (or 'exec \$SHELL') to pick up the updated PATH."
