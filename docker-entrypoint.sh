#!/usr/bin/env bash

set -e

rm -vf /run/php/*.pid

DOCKER_RUN_AS_GID=$(stat -c '%g' /var/www/html)
DOCKER_RUN_AS_UID=$(stat -c '%u' /var/www/html)

if [ "${DOCKER_RUN_AS_GID}" != "0" ]; then
  set +e
  groupadd --non-unique -g ${DOCKER_RUN_AS_GID} runasgroup
  set -e
  sed -i -e "s/^group\s.*$/group = ${DOCKER_RUN_AS_GID}/g" /etc/php/7.4/fpm/pool.d/www.conf
fi
if [ "${DOCKER_RUN_AS_UID}" != "0" ]; then
  set +e
  useradd --non-unique -c "User running container on docker host" -d /home/runasuser -g runasgroup -m -N -s /bin/bash -u ${DOCKER_RUN_AS_UID} runasuser
  set -e
  sed -i -e "s/^user\s.*$/user = ${DOCKER_RUN_AS_UID}/g" /etc/php/7.4/fpm/pool.d/www.conf
fi

# for ENVVAR in $(env | grep ^PHP_FPM_INI)
# do
#   ENVVAR_KEY=$(echo ${ENVVAR} | cut -d '=' -f 1)
#   PARAMETER=$(echo ${ENVVAR} | cut -d '=' -f 1 | cut -d '_' -f 4- | tr [:upper:] [:lower:])
#   ENVVAR_VALUE=${!ENVVAR_KEY}
#   LINE_FROM=$(grep ^${PARAMETER} /etc/php/7.4/fpm/php.ini)
#   sed -i -e "s/^${PARAMETER}\s.*$/${PARAMETER} = ${ENVVAR_VALUE}/g" /etc/php/7.4/fpm/php.ini
#   LINE_TO=$(grep ^${PARAMETER} /etc/php/7.4/fpm/php.ini)
#   echo Changing php.ini line:
#   echo "  from: "${LINE_FROM}
#   echo "  to: "${LINE_TO}
# done

exec /usr/sbin/php-fpm7.4 -R --nodaemonize --fpm-config /etc/php/7.4/fpm/php-fpm.conf

