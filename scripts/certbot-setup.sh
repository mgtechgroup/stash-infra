#!/bin/bash
set -euo pipefail

DOMAIN="${DOMAIN:-blbgensixai.club}"
EMAIL="${EMAIL:-admin@blbgensixai.club}"

echo "Setting up Let's Encrypt for ${DOMAIN}..."

if ! command -v certbot &> /dev/null; then
    if [ -f /etc/debian_version ]; then
        apt-get update && apt-get install -y certbot python3-certbot-nginx
    elif command -v yum &> /dev/null; then
        yum install -y certbot python3-certbot-nginx
    else
        echo "Unsupported OS. Install certbot manually."; exit 1
    fi
fi

certbot certonly --nginx -d "${DOMAIN}" -d "*.${DOMAIN}" \
    --email "${EMAIL}" --agree-tos --non-interactive --no-eff-email

sed -i "s|ssl_certificate .*|ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;|" /etc/nginx/conf.d/default.conf
sed -i "s|ssl_certificate_key .*|ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;|" /etc/nginx/conf.d/default.conf

nginx -t && nginx -s reload

CRON_JOB="0 0,12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'nginx -s reload'"
if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "${CRON_JOB}") | crontab -
fi

certbot renew --dry-run
echo "Certbot setup complete! Certs auto-renew twice daily."
