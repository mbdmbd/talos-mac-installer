# talos-mac-installer

Builds a GCC-linked Talos installer image and USB ISO for legacy Intel Mac minis
that cannot reliably cold-boot or reboot Talos v1.13+ with the stock kernel.

## Current target hardware

This fork is intended for:

- Macmini5,3
- Macmini6,1

Support is not yet proven. The generated ISO and installer must be tested on
non-critical hardware before being used for cluster upgrades.

## Why this exists

This repository follows the workaround developed by the upstream
`mebezac/talos-mac-installer` project.

Talos v1.13 uses an LLVM/LLD-linked Linux kernel. Some Intel Mac EFI firmware
does not successfully hand control to that EFI kernel image.

The workaround removes `LLVM: 1` from the Talos kernel package build, producing
a kernel linked with GCC and GNU ld.

This fork intentionally excludes the upstream project's T2-specific:

- i915 extension
- Thunderbolt extension
- `intel_iommu=on`
- `iommu=pt`
- `pcie_ports=compat`

## What the build does

1. Checks out the requested Talos release.
2. Reads the exact `siderolabs/pkgs` revision pinned by that release.
3. Rebuilds the kernel after removing `LLVM: 1`.
4. Builds the Talos imager and installer base using that kernel.
5. Produces:
   - a bootable `metal-amd64.iso`
   - a GHCR installer image suitable for `talosctl upgrade`

All other Talos packages remain the stock packages pinned by the selected Talos
release.

## Automation

`versions.env` contains the Talos version tracked by Renovate.

The GitHub Actions workflow runs:

- when `versions.env` changes on `main`, normally after merging a Renovate PR
- manually through `workflow_dispatch`

The workflow publishes:

- `ghcr.io/<owner>/talos-mac/installer:<version>`
- a matching ISO attached to the GitHub Release

## Local build requirements

Local builds require:

- Linux amd64
- Docker
- privileged BuildKit
- authenticated access to the target GHCR namespace

The build is not intended to run directly on macOS.

## Repository layout

```text
versions.env                     Talos version tracked by Renovate
profile.yaml.tmpl                Talos imager profile
scripts/build.sh                 Kernel and Talos build pipeline
scripts/gen-profile.sh           Renders ISO or installer profiles
.github/workflows/build-installer.yaml
renovate.json
```

## Safety and rollout

Do not immediately upgrade a working cluster node with a newly generated image.

The initial validation sequence is:

1. Build and download the ISO.
2. Boot a non-critical Mac from USB.
3. Confirm network, storage and Talos maintenance mode.
4. Test cold boot and reboot behaviour.
5. Only then test an installed node and in-place upgrade.
