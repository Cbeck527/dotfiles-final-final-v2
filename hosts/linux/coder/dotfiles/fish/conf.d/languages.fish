# Language-specific environment variables and PATH additions

# Python (XDG compliant)
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
set -gx GTAGSLABEL pygments
# XDG paths for Python tools
set -gx PYTHONUSERBASE $XDG_DATA_HOME/python
set -gx PYTHONPYCACHEPREFIX $XDG_CACHE_HOME/python
set -gx PIP_CACHE_DIR $XDG_CACHE_HOME/pip
set -gx UV_CACHE_DIR $XDG_CACHE_HOME/uv
# Add user base bin to PATH for pip --user installs
fish_add_path -gP $PYTHONUSERBASE/bin

# Rust (XDG compliant)
set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup
fish_add_path -gP $CARGO_HOME/bin

# Go (XDG compliant)
set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOMODCACHE $XDG_CACHE_HOME/go/mod
set -gx GOCACHE $XDG_CACHE_HOME/go/build
fish_add_path -gP $GOPATH/bin
