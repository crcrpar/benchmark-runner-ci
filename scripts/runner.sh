#!/bin/sh

set -e

KUROBAKO=${KUROBAKO:-./kurobako}
DIR=$(cd $(dirname $0); pwd)
BINDIR=$(dirname $DIR)/bin
TMPDIR=$(dirname $DIR)/tmp
REPEATS=${REPEATS:-5}
BUDGET=${BUDGET:-300}
SEED=${SEED:-1}
DIM=${DIM:-2}
SOLVERS=${SOLVERS:-all}
LOGLEVEL=${LOGLEVEL:-error}

usage() {
    cat <<EOF
$(basename ${0}) is an entrypoint to run benchmarkers.
Usage:
    $ $(basename ${0}) <problem> <json-path>
Problem:
    rosenbrock     : https://www.sfu.ca/~ssurjano/rosen.html
    himmelblau     : https://en.wikipedia.org/wiki/Himmelblau%27s_function
    ackley         : https://www.sfu.ca/~ssurjano/ackley.html
    rastrigin      : https://www.sfu.ca/~ssurjano/rastr.html
    weierstrass    : Weierstrass function in https://github.com/sigopt/evalset
    schwefel20     : https://www.sfu.ca/~ssurjano/schwef.html
    schwefel36     : https://www.sfu.ca/~ssurjano/schwef.html
    hpobench-naval
    hpobench-parkinson
    hpobench-protein
    hpobench-slice
Options:
    --help, -h         print this
Example:
    $ $(basename ${0}) rosenbrock ./tmp/kurobako.json
    $ cat ./tmp/kurobako.json | kurobako plot curve --errorbar -o ./tmp
EOF
}

RANDOM_SOLVER=$($KUROBAKO solver random)

case "$1" in
    hpobench-*)
        if [ ! -d "./fcnet_tabular_benchmarks" ] ; then
          if [ ! -f "./fcnet_tabular_benchmarks.tar.gz" ] ; then
            wget http://ml4aad.org/wp-content/uploads/2019/01/fcnet_tabular_benchmarks.tar.gz
          fi
          tar -xf ./fcnet_tabular_benchmarks.tar.gz
        else
          echo "HPOBench dataset has already downloaded."
        fi
        ;;
esac

case "$1" in
    himmelblau)
        PROBLEM=$($KUROBAKO problem command ${BINDIR}/himmelblau_problem)
        ;;
    rosenbrock)
        PROBLEM=$($KUROBAKO problem command ${BINDIR}/rosenbrock_problem)
        ;;
    ackley)
        PROBLEM=$($KUROBAKO problem sigopt --dim $DIM ackley)
        ;;
    rastrigin)
        # "kurobako problem sigopt --dim 8 rastrigin" only accepts 8-dim.
        PROBLEM=$($KUROBAKO problem command ${BINDIR}/rastrigin_problem $DIM)
        ;;
    weierstrass)
        PROBLEM=$($KUROBAKO problem sigopt --dim $DIM weierstrass)
        ;;
    schwefel20)
        PROBLEM=$($KUROBAKO problem sigopt --dim 2 schwefel20)
        ;;
    schwefel36)
        PROBLEM=$($KUROBAKO problem sigopt --dim 2 schwefel36)
        ;;
    hpobench-naval)
        PROBLEM=$($KUROBAKO problem hpobench "${TMPDIR}/fcnet_tabular_benchmarks/fcnet_naval_propulsion_data.hdf5")
        ;;
    hpobench-parkinson)
        PROBLEM=$($KUROBAKO problem hpobench "${TMPDIR}/fcnet_tabular_benchmarks/fcnet_parkinsons_telemonitoring_data.hdf5")
        ;;
    hpobench-protein)
        PROBLEM=$($KUROBAKO problem hpobench "${TMPDIR}/fcnet_tabular_benchmarks/fcnet_protein_structure_data.hdf5")
        ;;
    hpobench-slice)
        PROBLEM=$($KUROBAKO problem hpobench "${TMPDIR}/fcnet_tabular_benchmarks/fcnet_slice_localization_data.hdf5")
        ;;
    help|--help|-h)
        usage
        exit 0
        ;;
    *)
        echo "[Error] Invalid problem '${1}'"
        usage
        exit 1
        ;;
esac
case $SOLVERS in
    random)
        $KUROBAKO studies \
          --solvers \
            $RANDOM_SOLVER \
          --problems $PROBLEM \
          --seed $SEED --repeats $REPEATS --budget $BUDGET \
          | $KUROBAKO run --parallelism 7 > $2
        ;;
    *)
        echo "[Error] Invalid solver '${SOLVERS}'"
        usage
        exit 1
        ;;
esac
