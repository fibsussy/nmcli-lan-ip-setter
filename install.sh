#!/bin/bash
set -euo pipefail

sudo -v

show_help() {
    cat <<EOF_HELP
nmcli-lan-ip-setter Installer

Usage: $0 [OPTION] [VERSION]

Options:
  local     Build from source (default)
  -v, --version VERSION  Install specific git tag/version
  --help    Show this help message

Examples:
  $0 local            # Build from local source
  $0 -v v1.2.0        # Install version v1.2.0 from source
EOF_HELP
    exit 0
}

MODE="local"
VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        local)
            MODE="local"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

START_DIR=$(pwd)

if [ -f "$START_DIR/PKGBUILD" ] && [ -z "$VERSION" ]; then
    echo "Detected local repository..."
    [ -z "$MODE" ] && MODE="local"

    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    echo "Copying source files to temporary directory..."
    cd "$START_DIR"
    
    # Get tracked files that exist, plus untracked but trackable files
    {
        git ls-files --cached --exclude-standard | while IFS= read -r file; do
            [ -e "$file" ] && echo "$file"
        done
        git ls-files --others --exclude-standard
    } | tar -czf - -T - | (cd "$TMP_DIR" && tar xzf -)
    
    cd "$TMP_DIR"
    
    echo "Building package as normal user..."
    makepkg

    echo "Installing package as root..."
    sudo -v
    sudo pacman -U --noconfirm *.pkg.tar.zst
else
    echo "Remote install..."
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    cd "$TMP_DIR"
    if [ -n "$VERSION" ]; then
        # Try exact match first
        if git ls-remote --tags https://github.com/fibsussy/nmcli-lan-ip-setter.git | grep -q "refs/tags/$VERSION$"; then
            git -c advice.detachedHead=false clone --branch "$VERSION" https://github.com/fibsussy/nmcli-lan-ip-setter.git repo
            cd repo
        else
            # Find newest matching version
            echo "Finding newest version matching $VERSION..."
            LATEST_TAG=$(git ls-remote --tags https://github.com/fibsussy/nmcli-lan-ip-setter.git \
                | grep "refs/tags/.*$VERSION" \
                | sed 's|.*/\(.*\)|\1|' \
                | sort -V \
                | tail -n1)
            if [ -n "$LATEST_TAG" ]; then
                echo "Using version: $LATEST_TAG"
                git -c advice.detachedHead=false clone --branch "$LATEST_TAG" https://github.com/fibsussy/nmcli-lan-ip-setter.git repo
                cd repo
            else
                echo "Error: No version found matching $VERSION"
                exit 1
            fi
        fi
    else
        git clone https://github.com/fibsussy/nmcli-lan-ip-setter.git repo
        cd repo
    fi
    
    echo "Building package as normal user..."
    makepkg

    echo "Installing package as root..."
    sudo -v
    sudo pacman -U --noconfirm *.pkg.tar.zst
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"