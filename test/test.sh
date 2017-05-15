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
mkdir -p $LOG_DIR
printf "${BLUE}Logging to : $LOG_DIR\n${NC}"

printf "Starting Sinatra Server\n"
ruby ./test/assets/server.rb -o 0.0.0.0 &>$LOG_DIR/sinatra.log &
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
  rm -f $LOG_DIR/sinatra.log

  printf "Restarting Sinatra Server\n"
  ruby ./test/assets/server.rb -o 0.0.0.0 &>$LOG_DIR/sinatra.log &
  SINATRA_PID=$!
  printf "\nNew Server PID: $SINATRA_PID\n\n\n\n\n${NC}"
}

function clean_after_test {
  gobosh delete-deployment --force -n -d jmeter-dep

  mkdir -p "$LOG_DIR/archive"
  cp "$LOG_DIR/sinatra.log" "$LOG_DIR/archive/sinatra-$1.log"

  restart_sinatra
}

function deploy {
  printf "Deploying...\n"
  gobosh -d jmeter-dep deploy --no-redact -n \
        ./test/assets/jmeter-dep.yml \
        -o ./test/assets/ops/$1
  printf "\n\n"

  printf "waiting 1 second...\n"
  sleep 1
  printf "\n\n"
}

function assert_log_contains {
  if grep -q "$1" "$LOG_DIR/sinatra.log"; then
    printf "${GREEN}I found '$1'\n${NC}"
  else
    printf "${RED}BROKEN: Cannot find '$1' !!\n${NC}"
    exit 1
  fi
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

# ===================================================================
# ===================================================================
# TESTS

# ================================================
# GET
deploy "simple-get.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
clean_after_test "simple-get.yml"

# ================================================
deploy "simple-get-fail.yml"
assert_log_contains '\"GET /greeting/get/fail HTTP/1.1\" 400'
clean_after_test "simple-get-fail.yml"

# ================================================
deploy "simple-get-with-headers.yml"
assert_log_contains '\"GET /greeting/get/protected HTTP/1.1\" 200'
clean_after_test "simple-get-with-headers.yml"

# ================================================
# DELETE
deploy "simple-delete.yml"
assert_log_contains '\"DELETE /greeting/delete/smurf HTTP/1.1\" 200'
clean_after_test "simple-delete.yml"

# ================================================
deploy "simple-delete-with-headers.yml"
assert_log_contains '\"DELETE /greeting/delete/protected HTTP/1.1\" 201'
clean_after_test "simple-delete-with-headers.yml"

# ================================================
# PUT
deploy "simple-put.yml"
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 203'
clean_after_test "simple-put.yml"

# =================================================
deploy "simple-put-fail.yml"
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 405'
clean_after_test "simple-put-fail.yml"

# =================================================
deploy "simple-put-header-fail.yml"
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 401'
clean_after_test "simple-put-header-fail.yml"

# ================================================
# POST
deploy "simple-post.yml"
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 204'
clean_after_test "simple-post.yml"

# =================================================
deploy "simple-post-fail.yml"
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 402'
clean_after_test "simple-post-fail.yml"

# =================================================
deploy "simple-post-header-fail.yml"
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 401'
clean_after_test "simple-post-header-fail.yml"

# ================================================
# Multi Targets
deploy "multi-targets.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
assert_log_contains '\"DELETE /greeting/delete/smurf HTTP/1.1\" 200'
assert_log_contains '\"PUT /greeting/put/smurf HTTP/1.1\" 203'
assert_log_contains '\"POST /greeting/post/smurf HTTP/1.1\" 204'
clean_after_test "multi-targets.yml"

# ================================================
# RAW XML PLAN
deploy "raw-tornado.yml"
assert_log_contains '\"GET /greeting/get/smurf HTTP/1.1\" 200'
clean_after_test "raw-tornado.yml"

printf "${GREEN}=========================================================\n"
printf "${GREEN}Success: All Tests Passed !!!!!!!!!!!!!!!!!!!!\n"
printf "${GREEN}Success: All Tests Passed !!!!!!!!!!!!!!!!!!!!\n"
printf "${GREEN}Success: All Tests Passed !!!!!!!!!!!!!!!!!!!!\n"
printf "${GREEN}=========================================================${NC}\n"
