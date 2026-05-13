---
name: guix-packaging
description: Guide lines on how to package software and packages to Guix
---

> Workflow
> Package
> Patching
> Building
> Committing
> Validating
> History cleanup
> Fetching sources

## Workflow

- rg (ripgrep), which, find, xargs, jq, fzf, curl, grep, sed, coreutils, ruby, python3, git, cargo, and rust are all in the PATH
- Check package dependencies first; verify what already exists in Guix.
  You can use `guix search PACKAGE` to find more info on a package.
  For example `guix search hello`.
- Use `ls` command to look in `../factory/` or `../factory` (in current
  project) for local git checkouts of guix channels, the package or its dependencies. Follow symlinks.
- Do not load the contents of guix repositories guix-contrib and guix-gnu and their git histories into RAM. Use `rg` to
  search through them.
- Use ripgrep `rg` to search for packages that start with define-public PACKAGE.
- Use ripgrep `rg` instead of sed, it is in the path
- Do not ask for redirection permission for git and cd
- Do not ask for permission to fetch a hash
- Do not ask for permission for compound commands with cd and git that require approval to prevent bare repository attacks
- Do not ask for permission for command contains output redirection (>) which could write to arbitrary files
- Do not ask for permission to run git and guix commands
- Do not ask for permission to list directories
- Do not try to read /nix store
- During guix builds use background tasks without manual redirection
- Prefer matching the dependency versions already used in Guix.
- Do not download source code repositories without permission.
- Use the debian package in ../factory/debian for hints. You can also use contained Docker files for hints.
- If a dependency is missing in guix don't just start to download and package. Ask for permission first.
- Important: Use `guix gc --references PACKAGE` to look for existing package dependencies. Prefer it over text searches on .scm files. If that does not work you can also use `guix search -L PATH PACKAGE` to find dependencies.
- Write the output to a file package.scm

## Package

This section describes creating/writing a package:

- you can parse the files named bioinformatics.scm in factory for examples and hints
- give preference to gexp solutions
- Instead of using a lamba use #:make-flags to add parameters to make
- Try running tests. If that does not work use #:tests? #f and (important!) add an explanation as a comment
- list inputs before arguments in the guix package
- For Rust packages we should use the new guix rust importer following the information in guix-rust-package SKILL.md, i.e. /guix-rust-package
- You can use local-file for developing/testing a package. Buth the final version should always we a github git fetch or cargo download.
- avoid using git submodules, if possible. Make separate package definitions using git-fetch. I.e. unbundle!

## Patching

- Prefer to use guile code inside the package definition to make the package work.[
- Patch source code only when no other option exists.
- Use substitutes for simple text replacements. Use patch files when the change is complex.
- Never write patches by hand. Copy the original file, modify it, then generate a patch with `diff`.
- Do not commit patch files separately from the package definition.
- if there is an issue in current package due to dependency issue, fix dependency not patch

## Building

- Verify the package with `--dry-run` first.
- Build with `guix build ...`. If factory/guix-bioinformatics is available use something like:
`guix build -L ../guix-bioinformatics PACKAGE`
- Use `--no-offload` and redirect output with `&>` to a file.
- Use `timeout 100` and `tail` to monitor long builds.
- Try to avoid invalidate cache and force rebuilding the dependencies,
  however prefer Guix way and cleaner approach. Cleaner packaging is more
  important than cache

## Committing

- Use `commit-changes` skill for commit message format.
- Every new package is a separate commit.
- Commit each package together with its patch files.
- Commit package dependencies before the packages that need them.
  Introduce a dependency just-in-time -- in the same commit or
  immediately before the package that first requires it.
- Split infrastructure changes (build systems, modules, utilities)
  into separate commits from package definitions.
- Drop dead code and unused patch files.
- Preserve existing code comments; verify they are still relevant
  before committing.

## Validating

- Verify every commit with `--dry-run` before finalizing.
- For exported packages:
  `guix build PACKAGE --dry-run`
- For packages that are not exported:
  `guix build --no-offload -e '(@ (gnu packages foo) bar)' --dry-run`

## History cleanup

IMPORTANT: history cleanup is only by user request!

- Review full commit messages (`git log`, not `--oneline`) when
  cleaning up history.
- Reorder commits so dependencies come before dependents.
- Squash stale or fixup commits into their logical parent.
- Each commit in the final history should build cleanly on its own.

## Fetching sources

- If you need something from the web, fetch it to a local file first, then use it.
- You don't need to compute hashes during implementation via `guix download` or `guix hash`. Just use a dummy hash before running `guix build`.
- For git snapshots, use `let` with `commit` and `revision` variables (Guix convention):

 ```scheme
 (let ((commit "b908baf1825b1a89afef87b09e22c32af2ca6548")
       (revision "0"))
   ...
   (version (git-version "0.0.0" revision commit))
   (source (origin
             (method git-fetch)
             (uri (git-reference
                   (url "https://github.com/ggml-org/llama.cpp")
                   (commit commit)))
             (file-name (git-file-name name version))
             (sha256 (base32 "HASH")))))
```

## Test rebuilding all packages

- use `guix package -A` to list all packages in guix-bioinformatics, marked as gn/packages. Next rebuild all of them to test if the packages are valid. This can be done in the background. guix only builds packages that have changed, so it is often a cheap operation. Do not stop building. Just list all the failing packages.
