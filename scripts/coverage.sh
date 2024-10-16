#!/bin/bash

forge coverage --report lcov --no-match-test "statefulFuzz"

lcov -r lcov.info "tests/*" "contracts/MapleAbstractStrategy.sol" -o lcov-filtered.info --rc branch_coverage=1

genhtml lcov-filtered.info -o report --branch-coverage
