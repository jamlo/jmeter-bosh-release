#!/bin/bash

set -e -o pipefail

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`gobosh int ~/deployments/vbox/creds.yml --path /admin_password`
export BOSH_ENVIRONMENT=vbox

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOG_DIR=./tmp/JMETER-$(uuidgen)
TEST_WORKSPACE=$LOG_DIR/test_workspace
mkdir -p $LOG_DIR
mkdir -p $TEST_WORKSPACE
printf "${BLUE}Logging to : $LOG_DIR\n${NC}"

printf "Starting Sinatra Server\n"
ruby ./test/assets/server.rb -o 0.0.0.0 &>$TEST_WORKSPACE/sinatra.log &
SINATRA_PID=$!
printf "\n\n\n\n\n"

function final_cleanup {
  printf "${BLUE}Deleteing deployment ...\n"
  gobosh delete-deployment --force -n -d jmeter-dep
  printf "\n\n"

  gobosh clean-up -n

  printf "Running : killing sinatra PID '$SINATRA_PID'\n${NC}"
  kill -9 $SINATRA_PID
}

function restart_sinatra {
  printf "${BLUE}Running : killing sinatra PID '$SINATRA_PID'\n"
  kill -9 $SINATRA_PID
  printf "\n\n\n\n"

  printf "Restarting Sinatra Server\n"
  ruby ./test/assets/server.rb -o 0.0.0.0 &>$TEST_WORKSPACE/sinatra.log &
  SINATRA_PID=$!
  printf "\nNew Server PID: $SINATRA_PID\n\n\n\n\n${NC}"
}

function clean_up_logs_and_restart_sinatra {
  mkdir -p "$LOG_DIR/archive/$1-$2"
  cp -r "$TEST_WORKSPACE/" "$LOG_DIR/archive/$1-$2/"
  rm -rf $TEST_WORKSPACE
  mkdir -p $TEST_WORKSPACE
  restart_sinatra
}

function clean_after_test {
  gobosh delete-deployment --force -n -d jmeter-dep
  clean_up_logs_and_restart_sinatra $1 $2
}

function deploy {
  ops_files=""
  for var in "$@"
  do
    ops_files="$ops_files -o ./test/assets/ops/$var"
  done

  printf "Deploying...\n"
  gobosh -d jmeter-dep deploy --no-redact -n \
        ./test/assets/jmeter-dep.yml $ops_files

  printf "\n\n"

  printf "waiting 1 second...\n"
  sleep 1
  printf "\n\n"
}

function assert_log_contains {
  if grep -q "$1" "$TEST_WORKSPACE/sinatra.log"; then
    printf "${GREEN}I found '$1'\n${NC}"
  else
    printf "${RED}BROKEN: Cannot find '$1' !!\n${NC}"
    exit 1
  fi
}

function assert_log_contains_exact_count {
  number_of_occurances=$(grep -c "$1" "$TEST_WORKSPACE/sinatra.log")

  if [[ $number_of_occurances == "$2" ]]; then
    printf "${GREEN}I found '$2' occurances of '$1'\n${NC}"
  else
    printf "${RED}BROKEN: I found '$number_of_occurances' occurances of '$1', expected '$2'\n${NC}"
    exit 1
  fi
}

function assert_log_contains_less_than {
  number_of_occurances=$(grep -c "$1" "$TEST_WORKSPACE/sinatra.log")

  if [[ $number_of_occurances -lt "$2" ]]; then
    printf "${GREEN}I found '$number_of_occurances' occurances of '$1'. Less than '$2'\n${NC}"
  else
    printf "${RED}BROKEN: I found '$number_of_occurances' occurances of '$1', expected less than '$2'\n${NC}"
    exit 1
  fi
}

function assert_errand_result_tarball_contains {
  tarball_contents=$(tar -ztvf $TEST_WORKSPACE/test_node-*.tgz)

  for var in "$@"
  do
    if [[ $tarball_contents == *"$var"* ]]; then
      printf "${GREEN}I found '$var' in tarball contents\n${NC}"
    else
      printf "${RED}BROKEN: Cannot find '$var' in tarball contents !!\n${NC}"
      exit 1
    fi
  done
}

function run_errand {
  gobosh run-errand test_node -d jmeter-dep
}

function run_errand_keep_alive_download_logs {
  gobosh run-errand test_node -d jmeter-dep --keep-alive --download-logs --logs-dir=$TEST_WORKSPACE
}

function run_errand_download_logs {
  gobosh run-errand test_node -d jmeter-dep --download-logs --logs-dir=$TEST_WORKSPACE
}

# ==========================================================
# ==========================================================
trap final_cleanup EXIT

gobosh releases
mkdir -p ./tmp
gobosh create-release --force --tarball $LOG_DIR/jmeter-dev-release.tgz
gobosh upload-release $LOG_DIR/jmeter-dev-release.tgz
gobosh update-cloud-config -n ./test/assets/cloud-config.yml
printf "\n\n\n\n\n"

# =================================================================================================
# =================================================================================================
# TESTS

# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
TEST_MODE="tornado-mode"

# ================================================
# GET
deploy "$TEST_MODE/simple-get.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "simple-get"

# ================================================
deploy "$TEST_MODE/simple-get-fail.yml"
assert_log_contains '\"GET /greeting/get/fail HTTP/1.1\" 400'
clean_after_test "$TEST_MODE" "simple-get-fail"

# ================================================
deploy "$TEST_MODE/simple-get-with-headers.yml"
assert_log_contains '\"GET /greeting/get/protected HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "simple-get-with-headers"

# ================================================
# DELETE
deploy "$TEST_MODE/simple-delete.yml"
assert_log_contains '\"DELETE /greeting/delete/smurf HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "simple-delete"

# ================================================
deploy "$TEST_MODE/simple-delete-with-headers.yml"
assert_log_contains '\"DELETE /greeting/delete/protected HTTP/1.1\" 201'
clean_after_test "$TEST_MODE" "simple-delete-with-headers"

# ================================================
# PUT
deploy "$TEST_MODE/simple-put.yml"
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 203'
clean_after_test "$TEST_MODE" "simple-put"

# =================================================
deploy "$TEST_MODE/simple-put-fail.yml"
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 405'
clean_after_test "$TEST_MODE" "simple-put-fail"

# =================================================
deploy "$TEST_MODE/simple-put-header-fail.yml"
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 401'
clean_after_test "$TEST_MODE" "simple-put-header-fail"

# ================================================
# POST
deploy "$TEST_MODE/simple-post.yml"
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 204'
clean_after_test "$TEST_MODE" "simple-post"

# =================================================
deploy "$TEST_MODE/simple-post-fail.yml"
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 402'
clean_after_test "$TEST_MODE" "simple-post-fail"

# =================================================
deploy "$TEST_MODE/simple-post-header-fail.yml"
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 401'
clean_after_test "$TEST_MODE" "simple-post-header-fail"

# ================================================
# Multi Targets
deploy "$TEST_MODE/multi-targets.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_log_contains '\"DELETE /greeting/delete/smurf HTTP/1.1\" 200'
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 203'
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 204'
clean_after_test "$TEST_MODE" "multi-targets"

# ================================================
# RAW XML PLAN
deploy "$TEST_MODE/raw-tornado.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "raw-tornado"

# =================================================
# Simple Delayed Request
deploy "$TEST_MODE/simple-delayed-request.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_log_contains_less_than '\"GET /greeting/get/smurf HTTP/1.1\" 200' 6
clean_after_test "$TEST_MODE" "simple-delayed-request"

# =================================================
# Gaussian Random Timer
deploy "$TEST_MODE/gaussian-random-timer-request.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_log_contains_less_than '\"GET /greeting/get/smurf HTTP/1.1\" 200' 6
clean_after_test "$TEST_MODE" "gaussian-random-timer-request"

# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
TEST_MODE="storm-mode"

# =================================================
deploy "$TEST_MODE/simple-get.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "simple-get"

# ================================================
deploy "$TEST_MODE/simple-get-fail.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"GET /greeting/get/fail HTTP/1.1\" 400'
clean_after_test "$TEST_MODE" "simple-get-fail"

# ================================================
deploy "$TEST_MODE/simple-get-with-headers.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"GET /greeting/get/protected HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "simple-get-with-headers"

# ================================================
# DELETE
deploy "$TEST_MODE/simple-delete.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"DELETE /greeting/delete/smurf HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "simple-delete"

# ================================================
deploy "$TEST_MODE/simple-delete-with-headers.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"DELETE /greeting/delete/protected HTTP/1.1\" 201'
clean_after_test "$TEST_MODE" "simple-delete-with-headers"

# ================================================
# PUT
deploy "$TEST_MODE/simple-put.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 203'
clean_after_test "$TEST_MODE" "simple-put"

# =================================================
deploy "$TEST_MODE/simple-put-fail.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 405'
clean_after_test "$TEST_MODE" "simple-put-fail"

# =================================================
deploy "$TEST_MODE/simple-put-header-fail.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 401'
clean_after_test "$TEST_MODE" "simple-put-header-fail"

# ================================================
# POST
deploy "$TEST_MODE/simple-post.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 204'
clean_after_test "$TEST_MODE" "simple-post"

# =================================================
deploy "$TEST_MODE/simple-post-fail.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 402'
clean_after_test "$TEST_MODE" "simple-post-fail"

# =================================================
deploy "$TEST_MODE/simple-post-header-fail.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 401'
clean_after_test "$TEST_MODE" "simple-post-header-fail"

# ================================================
# Multi Targets
deploy "$TEST_MODE/multi-targets.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_log_contains '\"DELETE /greeting/delete/smurf HTTP/1.1\" 200'
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 203'
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 204'
clean_after_test "$TEST_MODE" "multi-targets"

#================================================
# RAW XML PLAN
deploy "$TEST_MODE/raw-storm.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
clean_after_test "$TEST_MODE" "raw-storm"

# =================================================
# Generate Dashboard
deploy "$TEST_MODE/simple-get.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml" "$TEST_MODE/3-generate-dashboard.yml"
run_errand_download_logs
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_errand_result_tarball_contains "jmeter_storm/jmeter.log" \
      "jmeter_storm/jmeter_storm.stderr.log" \
      "dashboard/content" \
      "jmeter_storm/log.jtl"
clean_after_test "$TEST_MODE" "generate-dashboard"

# =================================================
# Simple Delayed Request
deploy "$TEST_MODE/simple-delayed-request.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_log_contains_exact_count '\"GET /greeting/get/smurf HTTP/1.1\" 200' 2
clean_after_test "$TEST_MODE" "simple-delayed-request"

# =================================================
# Gaussian Random Timer
deploy "$TEST_MODE/gaussian-random-timer-request.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_log_contains_exact_count '\"GET /greeting/get/smurf HTTP/1.1\" 200' 8
clean_after_test "$TEST_MODE" "gaussian-random-timer-request"

# =================================================
# Running errand with keep alive works
deploy "$TEST_MODE/simple-get.yml" "$TEST_MODE/1-add-generic-workers.yml" "$TEST_MODE/2-add-errand-lifecycle.yml"
run_errand_keep_alive_download_logs
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_errand_result_tarball_contains "jmeter_storm/jmeter.log" \
      "jmeter_storm/jmeter_storm.stderr.log" \
      "dashboard/content" \
      "jmeter_storm/log.jtl"
clean_up_logs_and_restart_sinatra "$TEST_MODE" "run-errand-twice-1"
run_errand_keep_alive_download_logs
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_errand_result_tarball_contains "jmeter_storm/jmeter.log" \
      "jmeter_storm/jmeter_storm.stderr.log" \
      "dashboard/content" \
      "jmeter_storm/log.jtl"
clean_after_test "$TEST_MODE" "run-errand-twice-2"

printf "${GREEN}=========================================================\n"
printf "${GREEN}Success: All Tests Passed !!!!!!!!!!!!!!!!!!!!\n"
printf "${GREEN}Success: All Tests Passed !!!!!!!!!!!!!!!!!!!!\n"
printf "${GREEN}Success: All Tests Passed !!!!!!!!!!!!!!!!!!!!\n"
printf "${GREEN}=========================================================${NC}\n"
