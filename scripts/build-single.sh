#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/build-helpers.sh"

BUILD_YAML="${ROOT_DIR}/build.yaml"
COUNT=$(yq -r '.include | length' "${BUILD_YAML}")

echo "=== ビルドプリセット ==="
for i in $(seq 0 $((COUNT - 1))); do
  BOARD=$(yq -r ".include[${i}].board // \"\"" "${BUILD_YAML}")
  SHIELD=$(yq -r ".include[${i}].shield // \"\"" "${BUILD_YAML}")
  ARTIFACT=$(yq -r ".include[${i}].\"artifact-name\" // \"\"" "${BUILD_YAML}")
  LABEL="${ARTIFACT:-${SHIELD:-${BOARD}}}"
  echo "  $((i + 1))) ${LABEL}  [board: ${BOARD}]"
done

echo ""
read -rp "番号を選択してください (1-${COUNT}): " SEL
IDX=$((SEL - 1))

if [ "${IDX}" -lt 0 ] || [ "${IDX}" -ge "${COUNT}" ]; then
  echo "無効な選択です"
  exit 1
fi

BOARD=$(yq -r ".include[${IDX}].board" "${BUILD_YAML}")
SHIELD=$(yq -r ".include[${IDX}].shield // \"\"" "${BUILD_YAML}")
SNIPPET=$(yq -r ".include[${IDX}].snippet // \"\"" "${BUILD_YAML}")
CMAKE_ARGS=$(yq -r ".include[${IDX}].\"cmake-args\" // \"\"" "${BUILD_YAML}")
ARTIFACT=$(yq -r ".include[${IDX}].\"artifact-name\" // \"\"" "${BUILD_YAML}")

# アーティファクト名の決定
if [ -z "${ARTIFACT}" ]; then
  ARTIFACT="${SHIELD:-${BOARD}}-zmk"
  ARTIFACT="${ARTIFACT// /-}"
fi

BUILD_DIR="${ROOT_DIR}/build/${ARTIFACT}"

# CMake 引数の組み立て
EXTRA_MODULES="${ROOT_DIR};${WEST_WS}/zmk-layout-shift;${WEST_WS}/zmk-pmw3610-driver"

CMD=(west build -s zmk/app -d "${BUILD_DIR}" -b "${BOARD}")

if [ -n "${SNIPPET}" ]; then
  CMD+=(--snippet "${SNIPPET}")
fi

CMD+=(-- "-DZMK_CONFIG=${CONFIG_DIR}" "-DZMK_EXTRA_MODULES=${EXTRA_MODULES}")

if [ -n "${SHIELD}" ]; then
  CMD+=("-DSHIELD=${SHIELD}")
fi

if [ -n "${CMAKE_ARGS}" ]; then
  CMD+=("${CMAKE_ARGS}")
fi

echo ""
echo "=== ビルド開始: ${ARTIFACT} ==="
echo "  コマンド: ${CMD[*]}"
echo ""

cd "${WEST_WS}"
"${CMD[@]}"

copy_artifacts "${BUILD_DIR}" "${ARTIFACT}"
