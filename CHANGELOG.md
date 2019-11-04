# Changelog

**NB:** Versioning became consistent only after v2.1.0, before this many patches went unrecorded.

## [Latest](https://github.com/cortex-lab/alyx-matlab/commits/master) [2.3.1]

- Patch fix for assertion bug in newExp

## [2.3.0]

- Better support for local network repos (`913ac18`)
- Updated docs; added more string support (`23b0719`)
- Bug fix for error when registering file while not logged in (`9486be3`)
- Fixes for getFile, incl. workaround for db bug; test for getFilePath (`02ddd3c`, `d15f5f0`)
- Added 2 convenience functions, `url2eid` and `getExpRef` (`02ddd3c`)
- Changed default database to public test database (`b2081cb`)
- Fix for converting datetime str input to date (`3b19315`)

## [2.2.0]

- Removed various outdated functions (`bf923a0`)
- Improvements to changelog
- Added test for newExp with multiple remote repos (`e6df58`)
- Fix for file exist checks on new MATLAB versions (`29aea9`)

## [2.1.1]

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
