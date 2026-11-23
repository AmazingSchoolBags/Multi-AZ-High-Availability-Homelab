#!/usr/bin/env bash
# Contrôle non destructif sur l'hôte Ubuntu du lab. Aucun secret lu.
set -uo pipefail
command -v curl >/dev/null || { echo "curl introuvable" >&2; exit 2; }
failure=0
primary=0

check() {
  local label="$1" url="$2" expected="$3" code
  code=$(curl -sS --max-time 4 -o /dev/null -w '%{http_code}' "$url" 2>/dev/null) || code="000"
  printf '%-24s HTTP %s\n' "$label" "$code"
  [[ "$code" == "$expected" ]] || failure=1
}

echo "=== MULTIPASS ==="
if command -v multipass >/dev/null; then
  multipass zones || failure=1
  multipass list || failure=1
else
  echo "Multipass absent"
  failure=1
fi

echo "=== VIKUNJA ==="
check az1-vikunja http://10.97.0.8:3456/health 200
check az2-vikunja http://10.97.1.179:3456/health 200
check az3-vikunja http://10.97.2.141:3456/health 200

echo "=== PATRONI ==="
for entry in AZ1:10.97.0.14 AZ2:10.97.1.43 AZ3:10.97.2.128; do
  IFS=: read -r zone ip <<< "$entry"
  code=$(curl -sS --max-time 4 -o /dev/null -w '%{http_code}' "http://$ip:8008/primary" 2>/dev/null) || code="000"
  printf '%-24s HTTP %s\n' "$zone primary" "$code"
  if [[ "$code" == "200" ]]; then
    primary=$((primary + 1))
  elif [[ "$code" != "503" ]]; then
    failure=1
  fi
done
[[ "$primary" == 1 ]] || failure=1

echo "=== HAPROXY HTTP ==="
check haproxy http://127.0.0.1:8081/health 200
if (( failure )); then
  echo "ANOMALIE : contrôle complémentaire nécessaire"
  exit 1
fi
echo "OK : contrôles réseaux principaux réussis"
