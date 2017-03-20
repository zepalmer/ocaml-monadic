# Packaging

The following steps should be sufficient to package `ocaml-monadic` for distribution.

  1. Run `make clean && make test` one more time.

  2. Update version numbers and the like in the `_oasis` file.

  3. Run `oasis2opam --local` to generate an `opam` file.  Note that you'll need
     the `oasis2opam` OPAM package installed.  Commit the new files that are
     created.

  4. Use `opam pin add . jhupllib` and `opam pin remove jhupllib` to experiment
     with the package metadata and make sure it's ready for publishing.

  5. Run `opam-publish prepare jhupllib URL` where `URL` is the location of the
     GitHub tarball reflecting the commit you are trying to release.

  6. Run `opam-push submit DIR` where `DIR` is the directory created by
     `opam-publish prepare`.

  7. Follow the Travis CI builds on GitHub for the resulting pull request into
     the OPAM repository.

  8. Once the Travis CI is successful, tag the released commit.

  9. Modify the `_oasis` file to contain a modified version (e.g. `0.1+dev`) to
     distinguish the released version from future development.
