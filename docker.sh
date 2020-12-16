#!/usr/bin/env bash
stack_name="unit3d"
compose_file="docker-compose.yml"
repo_path="https://github.com/HDInnovations/UNIT3D-Community-Edition.git"
src_dir="./src"

if ! test -z "$REPO_URL"; then
  echo "Using custom repo: ${REPO_URL}"
  repo_path=$REPO_URL
fi

run_config() {
  ./scripts/configure_docker.sh
  docker-compose -f $compose_file -p $stack_name build
}

run_install() {
  if ! test -f ./Caddyfile; then
    run_config
  fi
  docker-compose -f ${compose_file} -p ${stack_name} build
  docker-compose -f ${compose_file} -p ${stack_name} up -d mariadb
  echo "Please wait while the database initializes, could take over a minute on slower hardware"
  ret_val=-1
  until [ $ret_val -eq 0 ]
  do
    docker-compose -f ${compose_file} -p ${stack_name} exec mariadb mysql -uunit3d -punit3d -D unit3d -s -e "SELECT 1" > /dev/null 2>&1
    ret_val=$?
    printf "."
    sleep 2
   done
   echo ""
   docker-compose -f ${compose_file} -p ${stack_name} up -d
   docker-compose -f ${compose_file} -p ${stack_name} logs -f
}

run_clean_config () {
  rm -rf ./Caddyfile \
    ./env
}

run_sql () {
  docker-compose -f ${compose_file} -p ${stack_name} up -d mariadb
  docker-compose -f ${compose_file} -p ${stack_name} exec mariadb mysql -uunit3d -punit3d -D unit3d
}

run_redis() {
  docker-compose -f ${compose_file} -p ${stack_name} up -d redis
  docker-compose -f ${compose_file} -p ${stack_name} exec redis redis-cli
}

run_update() {
  if [[ ! -d ${src_dir} ]]
  then
    git clone "${repo_path}" ${src_dir}
  else
    echo "${src_dir} already exists, skipping clone"
  fi

  cd ${src_dir} || echo "ERROR: src_dir (${src_dir}) does not exist!"
  git fetch
  latest=$(git tag -l | tail -n1)
  echo "Checking out latest branch: ${latest}"
  git checkout "${latest}"
  cd ..
}

run_clean () {
  rm -rf ./Caddyfile \
    ./env \
    ${src_dir}/public/css \
    ${src_dir}/public/fonts \
    ${src_dir}/public/js \
    ${src_dir}/public/mix-manifest.json \
    ${src_dir}/public/mix-sri.json \
    ${src_dir}/bootstrap/cache/*.php
}

run_prune() {
  docker system prune --volumes
}

run_up() {
  docker-compose -f ${compose_file} -p ${stack_name} build
  docker-compose -f ${compose_file} -p ${stack_name} up --remove-orphans -d
}

run_usage() {
  echo "Usage: $0 {artisan|build|clean|cleanall|config|down|exec|install|logs|prune|redis|run|sql}"
  exit 1
}

case "$1" in
  artisan)
    shift
    docker-compose -f ${compose_file} -p ${stack_name} exec app php artisan "$@"
    ;;
  build)
    shift
    docker-compose -f ${compose_file} -p ${stack_name} build "$@"
    ;;
  clean)
    run_clean
    ;;
  cleanall)
    run_clean
    run_clean_config
    ;;
  config)
    run_config "$2" "$3"
    ;;
  down)
    shift
    docker-compose -f ${compose_file} -p ${stack_name} down "$@"
    ;;
  exec)
    shift
    docker-compose -f ${compose_file} -p ${stack_name} exec "$@"
    ;;
  install)
    run_install
    ;;
  logs)
    shift
    docker-compose -f ${compose_file} -p ${stack_name} logs "$@"
    ;;
  prune)
    run_prune
    ;;
  redis)
    run_redis
    ;;
  run)
    shift
    docker-compose -f ${compose_file} -p ${stack_name} run --rm "$@"
    ;;
  sql)
    run_sql
    ;;
  up)
    shift
    docker-compose -f ${compose_file} -p ${stack_name} up -d "$@"
    docker-compose -f ${compose_file} -p ${stack_name} logs -f
    ;;
  update)
    run_update
    ;;
  *)
    run_usage
    ;;
esac