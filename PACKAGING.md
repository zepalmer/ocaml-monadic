# Packaging

The development branches of this repository do not contain information for OPAM packaging.  Instead, this metadata is contained in a branch named `packaging`.  This allows the packaged and distributed version of the software to contain minor differences.  Most notably, the `packaging` branch uses a *static* version of the OASIS setup, preventing the released package from depending upon OASIS while allowing the use of dynamic OASIS builds during development.

To package the software, follow these instructions:

  1. Merge the candidate for development into the `packaging` branch.
  2. Run `oasis setup` to generate a new `setup.ml` file.
  3. Build and run the tests to be sure that nothing has gone wrong.
  4. Update the contents of the `opam` directory accordingly.
  5. Create a commit for the release.
  6. Use `opam-publish` to create a submission.  For the tarball URL, GitHub's commit-based tarballs should work.
  7. Once the submission has passed all of the CI checks, tag the release.  If CI fails, correct the problem and return to step 5.
