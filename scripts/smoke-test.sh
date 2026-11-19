#!/bin/bash
set -eo pipefail

RETRY="--retry 5 --retry-connrefused --retry-delay 5"

echo "*****HOME*****"
home=$(curl -Ls $RETRY --proto '=https' --proto-redir '=https' https://bitwarden.localhost -w httpcode=%{http_code} --cacert rootCA.pem)
echo "$home" | lynx -stdin -dump -width=100
httpCode=$(echo "${home}" | grep -Po 'httpcode=\K(\d\d\d)')
if [[ ${httpCode} -ne 200 ]]; then
  echo "::error::ERROR: Home page failed to load.  HTTP code was $httpCode"; exit 1
fi
if ! grep -qi 'Bitwarden Web Vault' <<< "${home}"; then
  echo "::error::ERROR: Home page failed to load.  Please check body output above."; exit 1
fi
echo "Home OK."

echo "*****API/CONFIG*****"
config=$(curl -Ls $RETRY --proto '=https' --proto-redir '=https' https://bitwarden.localhost/api/config -w httpcode=%{http_code} --cacert rootCA.pem)
echo "$config" | lynx -stdin -dump -width=100
httpCode=$(echo "${config}" | grep -Po 'httpcode=\K(\d\d\d)')
if [[ ${httpCode} -ne 200 ]]; then
  echo "::error::ERROR: API/Config page failed to load.  HTTP code was $httpCode"; exit 1
fi
if ! grep -qF '"vault":"https://bitwarden.localhost"' <<< "${config}"; then
  echo "::error::ERROR: API/Config page failed to load.  Please check body output above."; exit 1
fi
echo "API/Config OK."

echo "*****ADMIN*****"
admin=$(curl -Ls $RETRY --proto '=https' --proto-redir '=https' https://bitwarden.localhost/admin -w httpcode=%{http_code} --cacert rootCA.pem)
echo "$admin" | lynx -stdin -dump -width=100
httpCode=$(echo "${admin}" | grep -Po 'httpcode=\K(\d\d\d)')
if [[ ${httpCode} -ne 200 ]]; then
  echo "::error::ERROR: Admin page failed to load.  HTTP code was $httpCode"; exit 1
fi
if ! grep -q 'Email login' <<< "${admin}"; then
  echo "::error::ERROR: Admin page failed to load.  Please check body output above."; exit 1
fi
echo "Admin OK."
