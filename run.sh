#!/bin/bash
set -euo pipefail

CONFIG_TEMPLATE="/var/www/agendav/config/settings.php.template"
CONFIG_FILE="/var/www/agendav/config/settings.php"
PHP_TZ_FILE="${PHP_INI_DIR}/conf.d/zz-agendav.ini"

AGENDAV_TITLE="${AGENDAV_TITLE:-AgenDAV}"
AGENDAV_FOOTER="${AGENDAV_FOOTER:-AgenDAV}"
AGENDAV_TIMEZONE="${AGENDAV_TIMEZONE:-UTC}"
AGENDAV_LANG="${AGENDAV_LANG:-en}"
AGENDAV_LOG_DIR="${AGENDAV_LOG_DIR:-/var/log/agendav}"
AGENDAV_WEEKSTART="${AGENDAV_WEEKSTART:-1}"
AGENDAV_CALDAV_PUBLIC_URL="${AGENDAV_CALDAV_PUBLIC_URL:-${AGENDAV_CALDAV_SERVER:-}}"
AGENDAV_CSRF_SECRET="${AGENDAV_CSRF_SECRET:-$(php -r 'echo bin2hex(random_bytes(32));')}"

if [ -z "${AGENDAV_CALDAV_SERVER:-}" ]; then
  echo "AGENDAV_CALDAV_SERVER is required"
  exit 1
fi

if [ "${AGENDAV_WEEKSTART}" != "0" ] && [ "${AGENDAV_WEEKSTART}" != "1" ]; then
  echo "AGENDAV_WEEKSTART must be 0 or 1"
  exit 1
fi

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

mkdir -p "${AGENDAV_LOG_DIR}"
cp "${CONFIG_TEMPLATE}" "${CONFIG_FILE}"

sed -i \
  -e "s/__AGENDAV_TITLE__/$(escape_sed "${AGENDAV_TITLE}")/g" \
  -e "s/__AGENDAV_FOOTER__/$(escape_sed "${AGENDAV_FOOTER}")/g" \
  -e "s/__AGENDAV_CSRF_SECRET__/$(escape_sed "${AGENDAV_CSRF_SECRET}")/g" \
  -e "s#__AGENDAV_LOG_DIR__#$(escape_sed "${AGENDAV_LOG_DIR}")#g" \
  -e "s#__AGENDAV_CALDAV_SERVER__#$(escape_sed "${AGENDAV_CALDAV_SERVER}")#g" \
  -e "s#__AGENDAV_CALDAV_PUBLIC_URL__#$(escape_sed "${AGENDAV_CALDAV_PUBLIC_URL}")#g" \
  -e "s/__AGENDAV_TIMEZONE__/$(escape_sed "${AGENDAV_TIMEZONE}")/g" \
  -e "s/__AGENDAV_LANG__/$(escape_sed "${AGENDAV_LANG}")/g" \
  -e "s/__AGENDAV_WEEKSTART__/${AGENDAV_WEEKSTART}/g" \
  "${CONFIG_FILE}"

sed -i -e "s/AGENDAV_TIMEZONE/$(escape_sed "${AGENDAV_TIMEZONE}")/g" "${PHP_TZ_FILE}"

php /var/www/agendav/bin/agendavcli migrations:migrate --no-interaction

if [ "x$1" = 'xapache2' ]; then
  echo "Start webserver"
  exec /usr/sbin/apache2ctl -D FOREGROUND
else
  exec "$@"
fi
