# talos-mac-installer

Builds a GCC and GNU ld-linked Talos installer image and USB ISO for legacy
Intel Mac minis that did not reliably cold-boot or reboot stock Talos v1.13.x.

## Validated target hardware

The custom Talos v1.13.7 installer was validated on 2026-08-01 on these two
cluster nodes:

| Model | Address | Installed boot path | Result |
|---|---|---|---|
| `Macmini5,3` | `192.168.1.151` | Retained GRUB layout; `bootedWithUKI` not reported | Upgrade and full cold boot succeeded |
| `Macmini6,1` | `192.168.1.153` | `systemd-boot` / UKI; `bootedWithUKI: true` | Upgrade and full cold boot succeeded |

Validated installer:

```text
ghcr.io/mbdmbd/talos-mac/installer:v1.13.7@sha256:4dc955cc925b23706346ef2c866a91952ee581b325bf29b62ad105c6e4cc0168
```

The running kernel on both nodes reported GCC 15.2.0 and GNU ld 2.46.0.20260210.
Both nodes returned after a full shutdown and physical power-on, and the four-node
Kubernetes cluster was `Ready` afterward.

This validation applies only to the two recorded systems. It does not establish
support for other Intel Mac models or configurations.

## Why this exists

This repository follows the workaround developed by the upstream
`mebezac/talos-mac-installer` project and the investigation recorded in
`siderolabs/talos#13579`.

Talos v1.13 stock kernels are built with LLVM and LLD. The workaround removes
`LLVM: 1` from the Talos kernel package build, producing a kernel built with GCC
and GNU ld.

The custom kernel is now an operationally validated workaround for the two
systems above. The tests do not prove that compiler/linker choice is the only
variable involved in every boot path: both the official and custom v1.13.7 ISOs
also booted through Ventoy GRUB2 mode, while the custom ISO hung through the
2012 Mac's native removable-media EFI path. Installed boot validation remains
the decisive test.

This fork intentionally excludes the upstream project's T2-specific:

- i915 extension
- Thunderbolt extension
- `intel_iommu=on`
- `iommu=pt`
- `pcie_ports=compat`

## What the build does

1. Checks out the requested Talos release.
2. Reads the exact `siderolabs/pkgs` revision pinned by that release.
3. Downloads the matching kernel source from the GitHub kernel mirror used by
   the build workaround.
4. Rebuilds the kernel after removing `LLVM: 1`.
5. Builds the Talos kernel, initramfs, installer base and imager using the custom
   kernel.
6. Produces:
   - `metal-amd64.iso`
   - a GHCR installer image suitable for `talosctl upgrade`

All non-kernel Talos packages remain the stock packages pinned by the selected
Talos release.

## Published artifacts

The workflow publishes:

- `ghcr.io/<owner>/talos-mac/installer:<version>`
- an ISO attached to a GitHub Release tagged `mac-<version>`

Production use should pin the installer by digest:

```text
ghcr.io/<owner>/talos-mac/installer:<version>@sha256:<digest>
```

## Automation

`versions.env` contains the stable Talos version tracked by Renovate.

The GitHub Actions workflow runs:

- when `versions.env` changes on `main`, normally after Renovate automatically
  squash-merges a stable Talos release update
- manually through `workflow_dispatch`, optionally overriding the version

Pull requests do not build the kernel because the compile is expensive.

## Validation and rollout policy

A successful build is not approval to upgrade both cluster nodes.

For every new Talos release:

1. Confirm the workflow, release asset, installer tag and immutable digest.
2. Upgrade `Macmini5,3` at `192.168.1.151` first.
3. Verify the running Talos version and `/proc/version` compiler/linker string.
4. Perform a graceful shutdown and physical cold boot.
5. Confirm the node returns to Kubernetes as `Ready`.
6. Repeat the complete process on `Macmini6,1` at `192.168.1.153` because it
   uses the UKI boot path rather than the retained GRUB layout.

The native USB ISO path is not a required gate. Ventoy 1.1.17 GRUB2 mode is the
validated recovery and diagnostic path for the v1.13.7 official and custom
ISOs. It is not the normal installed boot method.

Installation and upgrades remain manual. Keep physical access, known-good media
and the recorded previous installer available during cold-boot validation.

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
