#!/bin/bash
set -eo pipefail

RETRY="--retry 5 --retry-connrefused --retry-delay 5"

echo "*****HOME*****"
home=$(curl -Ls $RETRY --proto '=https' --proto-redir '=https' https://bitwarden.localhost -w httpcode=%{http_code} --cacert rootCA.pem)
echo "$home" | lynx -stdin -dump -width=100
httpCode=$(echo "${home}" | grep -Po 'httpcode=\K(\d\d\d)')
bodyCheck=$(echo "${home}" | grep -Pio 'Bitwarden Web Vault')
if [[ ${httpCode} -ne 200 ]]; then
  echo "::error::ERROR: Home page failed to load.  HTTP code was $httpCode"; exit 1
fi
if [[ "${bodyCheck,,}" != "bitwarden web vault" ]]; then
  echo "::error::ERROR: Home page failed to load.  Please check body output above."; exit 1
fi
echo "Home OK."

echo "*****API/CONFIG*****"
config=$(curl -Ls $RETRY --proto '=https' --proto-redir '=https' https://bitwarden.localhost/api/config -w httpcode=%{http_code} --cacert rootCA.pem)
echo "$config" | lynx -stdin -dump -width=100
httpCode=$(echo "${config}" | grep -Po 'httpcode=\K(\d\d\d)')
bodyCheck=$(echo "${config}" | grep -Po '\"vault\":\"https://bitwarden\.localhost\"')
if [[ ${httpCode} -ne 200 ]]; then
  echo "::error::ERROR: API/Config page failed to load.  HTTP code was $httpCode"; exit 1
fi
if [[ "$bodyCheck" != '"vault":"https://bitwarden.localhost"' ]]; then
  echo "::error::ERROR: API/Config page failed to load.  Please check body output above."; exit 1
fi
echo "API/Config OK."

echo "*****ADMIN*****"
admin=$(curl -Ls $RETRY --proto '=https' --proto-redir '=https' https://bitwarden.localhost/admin -w httpcode=%{http_code} --cacert rootCA.pem)
echo "$admin" | lynx -stdin -dump -width=100
httpCode=$(echo "${admin}" | grep -Po 'httpcode=\K(\d\d\d)')
bodyCheck=$(echo "${admin}" | grep -Po "We'll email you a secure login link")
if [[ ${httpCode} -ne 200 ]]; then
  echo "::error::ERROR: Admin page failed to load.  HTTP code was $httpCode"; exit 1
fi
if [[ "$bodyCheck" != "We'll email you a secure login link" ]]; then
  echo "::error::ERROR: Admin page failed to load.  Please check body output above."; exit 1
fi
echo "Admin OK."
