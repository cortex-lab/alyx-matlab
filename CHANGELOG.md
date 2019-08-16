# Changelog

**NB:** Versioning became consistent only after v2.1.0, before this many patches went unrecorded.

## Next release

- Removed various outdated functions (`bf923a0`)
- Improvements to changelog
- Added test for newExp with multiple remote repos (`e6df58`)
- Fix for file exist checks on new MATLAB versions (`29aea9`)

## [Latest](https://github.com/cortex-lab/alyx-matlab/commits/master) [2.1.1]

- Patch fix for class constructor default url used instead of paths (`10fdb2c`)
- Added changelog (`e369d3`)

## [2.1.0]

- Function for extracting behaviour ALF files (`77995f`)
- Client-side validation of files during registration (`a154f7`)

## [2.0.0]

- Alyx now a value class rather than a package (`5b6ebb`)
- Better error handling and documentation (`da9319`)
- Major improvements to registerFile (`2e741c`)
- Added support for when database unreachable (`6b92ba`)
- Added PUT and PATCH methods; using MATLAB builtins for JSON (`ddc0d8`)

## [1.0.0]

- Added +alyx package and generic functions for posting water, file registration, etc.
- Test suite added (`e9b4b9`)
