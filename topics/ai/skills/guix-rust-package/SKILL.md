---
name: guix-rust-package
description: Guide lines on how to a Rust PACKAGE from a checked out git source repository to Guix
---


> Package

# Package

We are going to create guix packages. The following applies to Rust/Cargo packages only:

- Load the /guix-packaging SKILL, i.e., guix-packaging SKILL.md. Do not continue without this skill.
- On success show /context
- I checked out the PACKAGE source code in the factory dir
- When parsing a rust source directory, ignore target/ dir, Cargo.lock and **/*.rs.bk files
- Write any new rust packages to a rust-package.scm file (not package.scm)
- For Rust packages we should start with the new guix rust importer: from the git PACKAGE source directory `guix import crate -f Cargo.lock PACKAGE`. This should resolve all dependencies, except for the one we want to build. If there dependencies that don't build, please stop and notify me. See if there are duplicates with the packages already in claude-general/rust-package.scm and in guix itself before writing rust-package.scm.
- Take hints from files in factory/guix-gnu/ named rust-crates.scm and rust-apps.scm
- Create new packages for rust dependencies, first trying the importer
- When there are version mismatches fix them one at a time - do not try to do in bulk
- In the final step make sure to build the package
- Important: Use `guix gc --references PACKAGE` to look for existing package dependencies. Prefer it over text searches on .scm files.
- On success show stats with /context

The old type packages use or inherit

```scheme
 (build-system cargo-build-system)
```

The new type packages do not directly call the cargo-build-system and look like

```scheme
(define rust-abscissa-core-0.8.2
  (crate-source "abscissa_core" "0.8.2"
                "0fvpm79dnwh1lj5kpw1bs3sfs8drcwbvbic6vrmjsh34v1x1i0rh"))
```

as produced by `guix import crate -f Cargo.lock PACKAGE`

- To install rust with cargo do `guix package -i rust rust:cargo`
- If you need other software use `guix search PACKAGE` and `guix package -i PACKAGE` to install software/quit
- configure phase (not unpack-rust-crates) does the actual tarball extraction into guix-vendor/STORENAME/
- configure also DELETES Cargo.lock - no point patching it
- Vendor dir names use strip-store-file-name (e.g. rust-home-0.5.12.tar.gz/), not name-version/
- add-before 'build is the right hook for patching vendored create metadata
- when building a guix package sleep 30 seconds instead of 300
- You can use local-file for developing/testing a package. Buth the final version should always we a github git fetch or cargo download.
