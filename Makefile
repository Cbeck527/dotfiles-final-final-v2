IMPURE ?= false

UNAME := $(shell uname)
HOSTNAME := $(shell hostname)

# Channels
NIX_CHANNELS := nixpkgs-master nixpkgs-stable nixpkgs-unstable
HOME_CHANNELS := home-manager
OSX_CHANNELS := nix-darwin nix-homebrew homebrew-core homebrew-cask
EXTRA_CHANNELS := fenix

impure := $(if $(filter $(IMPURE),true),--impure,)


ifeq ($(UNAME), Darwin) # darwin targets
all: switch

switch:
	TERM=xterm darwin-rebuild switch ${impure} --verbose --flake ".#$(HOSTNAME)" --fallback --option sandbox false

check:
	nix flake check

build:
	nix build ".#darwinConfigurations.$(HOSTNAME).system" --dry-run

# Fresh install: nix run nix-darwin -- switch --flake .#HOSTNAME

endif # end osx


# TODO: set up linux machines with home-manager
ifeq ($(UNAME), Linux) # linux targets

all:
	@echo "switch.linux"

switch.linux:
	nix build .#homeConfigurations.linux.activationPackage
	./result/activate switch ${impure} --verbose; ./result/activate

endif # end linux

clean:
	nix-collect-garbage

fclean:
	@echo "/!\ require to be root"
	sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old
	nix-collect-garbage -d

lock: lock.nix lock.osx lock.home
lock.nix:; nix flake lock $(NIX_CHANNELS)
lock.osx:; nix flake lock $(OSX_CHANNELS)
lock.home:; nix flake lock $(HOME_CHANNELS)

update: update.nix update.osx update.home update.extra update.claude
update.nix:; nix flake update $(NIX_CHANNELS)
update.osx:; nix flake update $(OSX_CHANNELS)
update.home:; nix flake update $(HOME_CHANNELS)
update.extra:; nix flake update $(EXTRA_CHANNELS)

# Update individual packages without touching other inputs
update.claude:; nix flake update nixpkgs-claude-code
