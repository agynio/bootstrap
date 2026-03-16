#!/usr/bin/env bash

set -euo pipefail

auto_yes="false"

usage() {
  cat <<'EOF'
Usage: ./install-ca-cert.sh [-y] <path-to-ca-cert>

Options:
  -y    Install without prompting for confirmation.
EOF
}

while getopts ":yh" opt; do
  case "${opt}" in
    y)
      auto_yes="true"
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

cert_path="$1"

if [[ ! -f "${cert_path}" ]]; then
  echo "Error: certificate file not found at ${cert_path}." >&2
  exit 1
fi

sudo_prefix=()
if [[ "$(id -u)" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required but not available." >&2
    exit 1
  fi
  sudo_prefix=(sudo)
fi

os_name="$(uname -s)"
case "${os_name}" in
  Darwin)
    platform="macos"
    ;;
  Linux)
    platform="linux"
    ;;
  *)
    echo "Error: unsupported OS ${os_name}." >&2
    exit 1
    ;;
esac

cert_name="$(basename "${cert_path}")"
if [[ "${cert_name}" != *.crt ]]; then
  cert_name="${cert_name}.crt"
fi

if [[ "${platform}" == "linux" ]]; then
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
  fi

  os_id="${ID:-}"
  os_like="${ID_LIKE:-}"

  if [[ "${os_id}" == "ubuntu" || "${os_id}" == "debian" || "${os_like}" == *"debian"* ]]; then
    dest_dir="/usr/local/share/ca-certificates"
    dest_path="${dest_dir}/${cert_name}"
    update_cmd=(update-ca-certificates)
  elif [[ "${os_id}" == "alpine" ]]; then
    dest_dir="/usr/local/share/ca-certificates"
    dest_path="${dest_dir}/${cert_name}"
    update_cmd=(update-ca-certificates)
  elif [[ "${os_id}" == "rhel" || "${os_id}" == "fedora" || "${os_id}" == "centos" || "${os_like}" == *"rhel"* || "${os_like}" == *"fedora"* || "${os_like}" == *"centos"* ]]; then
    dest_dir="/etc/pki/ca-trust/source/anchors"
    dest_path="${dest_dir}/${cert_name}"
    update_cmd=(update-ca-trust extract)
  else
    echo "Error: unsupported Linux distribution (ID=${os_id} ID_LIKE=${os_like})." >&2
    exit 1
  fi

  if ! command -v "${update_cmd[0]}" >/dev/null 2>&1; then
    echo "Error: required command '${update_cmd[0]}' not found." >&2
    exit 1
  fi

  install_description=$(cat <<EOF
This will install the CA certificate for ${os_id:-linux}:
- Source: ${cert_path}
- Destination: ${dest_path}
- Commands:
  - sudo cp "${cert_path}" "${dest_path}"
  - sudo ${update_cmd[*]}
Sudo privileges are required.
EOF
)

  if [[ "${auto_yes}" != "true" ]]; then
    echo "${install_description}"
    if ! read -r -p "Proceed? [y/N]: " response; then
      echo "Error: failed to read confirmation." >&2
      exit 1
    fi
    case "${response}" in
      [yY]|[yY][eE][sS])
        ;;
      *)
        echo "Aborted."
        exit 1
        ;;
    esac
  fi

  "${sudo_prefix[@]}" cp "${cert_path}" "${dest_path}"
  "${sudo_prefix[@]}" "${update_cmd[@]}"
else
  if ! command -v security >/dev/null 2>&1; then
    echo "Error: required command 'security' not found." >&2
    exit 1
  fi

  install_description=$(cat <<EOF
This will install the CA certificate into the macOS system keychain:
- Source: ${cert_path}
- Command:
  - sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${cert_path}"
Sudo privileges are required.
EOF
)

  if [[ "${auto_yes}" != "true" ]]; then
    echo "${install_description}"
    if ! read -r -p "Proceed? [y/N]: " response; then
      echo "Error: failed to read confirmation." >&2
      exit 1
    fi
    case "${response}" in
      [yY]|[yY][eE][sS])
        ;;
      *)
        echo "Aborted."
        exit 1
        ;;
    esac
  fi

  "${sudo_prefix[@]}" security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${cert_path}"
fi
