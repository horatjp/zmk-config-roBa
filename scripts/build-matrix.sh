#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/build-helpers.sh"

PARALLEL=0
JOBS=""

for arg in "$@"; do
  case "${arg}" in
    --parallel)   PARALLEL=1 ;;
    --parallel=*) PARALLEL=1; JOBS="${arg#*=}" ;;
  esac
done

BUILD_YAML="${ROOT_DIR}/build.yaml"
COUNT=$(yq -r '.include | length' "${BUILD_YAML}")
EXTRA_MODULES="${ROOT_DIR};${WEST_WS}/zmk-layout-shift;${WEST_WS}/zmk-pmw3610-driver"

build_job() {
  local idx="${1}"

  local board shield snippet cmake_args artifact
  board=$(yq -r ".include[${idx}].board" "${BUILD_YAML}")
  shield=$(yq -r ".include[${idx}].shield // \"\"" "${BUILD_YAML}")
  snippet=$(yq -r ".include[${idx}].snippet // \"\"" "${BUILD_YAML}")
  cmake_args=$(yq -r ".include[${idx}].\"cmake-args\" // \"\"" "${BUILD_YAML}")
  artifact=$(yq -r ".include[${idx}].\"artifact-name\" // \"\"" "${BUILD_YAML}")

  if [ -z "${artifact}" ]; then
    artifact="${shield:-${board}}-zmk"
    artifact="${artifact// /-}"
  fi

  local build_dir="${ROOT_DIR}/build/${artifact}"

  local cmd=(west build -s zmk/app -d "${build_dir}" -b "${board}")

  if [ -n "${snippet}" ]; then
    cmd+=(--snippet "${snippet}")
  fi

  cmd+=(-- "-DZMK_CONFIG=${CONFIG_DIR}" "-DZMK_EXTRA_MODULES=${EXTRA_MODULES}")

  if [ -n "${shield}" ]; then
    cmd+=("-DSHIELD=${shield}")
  fi

  if [ -n "${cmake_args}" ]; then
    cmd+=("${cmake_args}")
  fi

  echo "=== ビルド開始: ${artifact} ==="

  cd "${WEST_WS}"
  "${cmd[@]}"

  copy_artifacts "${build_dir}" "${artifact}"
}

if [ "${PARALLEL}" -eq 1 ]; then
  JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
  echo "並列ビルド (jobs=${JOBS})"

  PIDS=()
  for i in $(seq 0 $((COUNT - 1))); do
    build_job "${i}" &
    PIDS+=($!)
  done

  FAILED=0
  for pid in "${PIDS[@]}"; do
    wait "${pid}" || FAILED=1
  done

  [ "${FAILED}" -eq 0 ] || { echo "❌ 一部のビルドが失敗しました"; exit 1; }
else
  for i in $(seq 0 $((COUNT - 1))); do
    build_job "${i}"
  done
fi

echo ""
echo "=== 全ビルド完了 → ${OUTPUT_DIR} ==="
ls -lh "${OUTPUT_DIR}/"
