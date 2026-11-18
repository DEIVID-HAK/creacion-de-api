# ============================================================
# Laboratorio de Clústeres - Simulación de Failover
# Versión para Windows PowerShell
# Requisitos: Docker Desktop, curl
# ============================================================

$ErrorActionPreference = "Stop"

# 1. Iniciar el Clúster de Alta Disponibilidad
Write-Host "=== [1/4] Iniciando el clúster de alta disponibilidad ==="
docker compose up -d
Start-Sleep -Seconds 5

# 2. Probar el balanceo de carga (Round-Robin alternado)
Write-Host "`n=== [2/4] Peticiones iniciales al balanceador (Round-Robin) ==="
for ($i = 1; $i -le 4; $i++) {
    $resp = curl.exe -s http://localhost:8080/
    Write-Host "Peticion $i -> $resp"
    Start-Sleep -Seconds 1
}

# 3. Simular la caída del servidor principal de aplicación (Node 1)
Write-Host "`n=== [3/4] Simulando fallo: deteniendo el Nodo 1 ==="
docker stop techsolutions_app_node1
Start-Sleep -Seconds 2

# 4. Verificar la conmutación automática de tráfico al Nodo 2
Write-Host "`n--- Peticiones DURANTE la falla (Failover) ---"
for ($i = 1; $i -le 4; $i++) {
    $resp = curl.exe -s -w " [HTTP %{http_code}]" http://localhost:8080/
    Write-Host "Peticion $i -> $resp"
    Start-Sleep -Seconds 1
}

# 5. Recuperar el Nodo 1 y verificar reintegración
Write-Host "`n=== [4/4] Restaurando el Nodo 1 ==="
docker start techsolutions_app_node1
Start-Sleep -Seconds 3

Write-Host "`n--- Peticiones DESPUÉS de la recuperación ---"
for ($i = 1; $i -le 4; $i++) {
    $resp = curl.exe -s -w " [HTTP %{http_code}]" http://localhost:8080/
    Write-Host "Peticion $i -> $resp"
    Start-Sleep -Seconds 1
}

Write-Host "`n=== Estado final de los contenedores ==="
docker compose ps