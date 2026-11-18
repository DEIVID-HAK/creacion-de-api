#!/bin/bash
# ============================================================
# Laboratorio de Clústeres - Simulación de Failover
# Requisitos: Docker, Docker Compose, curl, jq
# ============================================================

set -e

# 1. Iniciar el Clúster de Alta Disponibilidad
echo "=== [1/4] Iniciando el clúster de alta disponibilidad ==="
docker compose up -d --build
sleep 5

# 2. Probar el balanceo de carga (Round-Robin alternado)
echo ""
echo "=== [2/4] Peticiones iniciales al balanceador (Round-Robin) ==="
for i in {1..4}; do
  echo "Petición $i -> $(curl -s http://localhost:8080/)"
  sleep 1
done

# 3. Simular la caída del servidor principal de aplicación (Node 1)
echo ""
echo "=== [3/4] Simulando fallo: deteniendo Nodo 1 ($(docker stop techsolutions_app_node1)) ==="
sleep 2

# 4. Verificar la conmutación automática de tráfico al Nodo 2
echo ""
echo "--- Peticiones DURANTE la falla (Failover) ---"
for i in {1..4}; do
  echo "Petición $i -> $(curl -s -w ' [HTTP %{http_code}]' http://localhost:8080/)"
  sleep 1
done

# 5. Recuperar el Nodo 1 y verificar reintegración
echo ""
echo "=== [4/4] Restaurando Nodo 1 (docker start techsolutions_app_node1) ==="
docker start techsolutions_app_node1
sleep 3

echo "--- Peticiones DESPUÉS de la recuperación ---"
for i in {1..4}; do
  echo "Petición $i -> $(curl -s -w ' [HTTP %{http_code}]' http://localhost:8080/)"
  sleep 1
done

echo ""
echo "=== Estado final de los contenedores ==="
docker compose ps