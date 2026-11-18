# TODO API - Proyecto Formativo

API REST para gestión de tareas, desarrollada con **Node.js + Express + PostgreSQL** (SQL puro con el driver `pg`), dockerizada con Docker Compose y lista para desplegar en **Render**.

## Tecnologías

- Node.js 20
- Express
- PostgreSQL 16 (driver `pg`)
- Docker / Docker Compose
- pgAdmin 4 (interfaz gráfica, opcional)

## Estructura del proyecto

```
.
├── src/
│   └── index.js            # API Express + conexión PostgreSQL
├── db/
│   └── init.sql            # Esquema y datos semilla (solo 1er arranque)
├── Dockerfile
├── docker-compose.yml      # Servicios: db (postgres), api, pgadmin
├── .env.example            # Variables de ejemplo
```

## API

| Método | Endpoint           | Cuerpo (JSON)                      | Acción            |
|--------|--------------------|------------------------------------|-------------------|
| GET    | /                  | -                                  | Mensaje de bienvenida |
| GET    | /api/tasks         | -                                  | Listar tareas     |
| POST   | /api/tasks         | `{"title":"Mi tarea","description":"..."}` | Crear tarea  |
| PUT    | /api/tasks/:id     | `{"completed":true}`               | Actualizar tarea  |
| DELETE | /api/tasks/:id     | -                                  | Eliminar tarea    |

## Instalación Local (sin Docker)

Requisitos: Node.js 18+ y PostgreSQL corriendo en `localhost:5432`.

```bash
npm install
# crea una base "tododb" con usuario "todo" / "todo123" o ajusta .env
cp .env.example .env
npm run dev
```

## Despliegue con Docker Compose

```bash
docker-compose up -d
```

- API: http://localhost:3000
- pgAdmin: http://localhost:5080 (email `admin@todoapi.com`, password `admin123`)

Comandos útiles:

```bash
docker-compose ps           # estado de los contenedores
docker-compose logs -f api  # logs de la API
docker-compose down         # detener (conserva el volumen pg_data)
docker-compose down -v      # detener y borrar datos de la BD
```

> La tabla `tasks` y los datos de ejemplo se crean automáticamente la primera vez mediante `db/init.sql`. La API también ejecuta un `CREATE TABLE IF NOT EXISTS` al arrancar.

## Despliegue en Render (PostgreSQL)

Render ofrece un **PostgreSQL gratis** integrado, así que no necesitas MongoDB Atlas.

### 1. Subir el código a GitHub

```bash
git init
git add .
git commit -m "API de Tareas lista para producción (PostgreSQL)"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/proyecto-todo-api.git
git push -u origin main
```

### 2. Crear la base de datos

1. En [render.com](https://render.com) → **New +** → **PostgreSQL**.
2. Name: `todo-db`, Database: `tododb`, **Free** → **Create Database**.
3. Copia la **Internal Database URL** (se verá como `postgres://usuario:pass@host:5432/tododb`).

### 3. Crear el Web Service (la API)

1. **New +** → **Web Service** → conecta tu repositorio de GitHub.
2. Configura:
   - **Name**: `todo-api`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: `Free`
3. En **Environment / Advanced** agrega:
   - `PORT` = `10000` (Render lo define automáticamente; el código usa `process.env.PORT`)
   - `DATABASE_URL` = la Internal Database URL de tu base de datos Render
4. **Create Web Service**. Render construye y despliega solo.

> La app activa SSL automáticamente cuando existe la variable `PGSSL=true`. En **Advanced → Environment Variables** puedes agregar `PGSSL` = `true` si Render exige conexión TLS (suele ser el caso del plan free).

### 4. Probar en la nube

Tu API quedará en una URL similar a:

```
https://todo-api.onrender.com
https://todo-api.onrender.com/api/tasks
```

Usa Postman/Insomnia con la misma tabla de endpoints de arriba, cambiando `localhost:3000` por tu URL de Render.

## Plan de Implantación (resumen para el informe)

| Aspecto | Detalle |
|---|---|
| Estrategia | Implantación Directa (proyecto pequeño, riesgo bajo) |
| Ubicación | Local (Docker Compose) + Nube (Render, plan free) |
| Base de datos | PostgreSQL 16 (local) / PostgreSQL gestionado (Render) |
| Riesgos | Caída/sleep del servicio gratuito de Render; límites de memoria; credenciales expuestas → usar variables de entorno |
| Cronograma | F1 entorno (30 min) → F2 Docker (45 min) → F3 Compose (1 h) → F4 Render (1.5 h) → F5 documentación (1 h) |

## Evidencias requeridas (Fase 5)

1. API funcionando en local (`http://localhost:3000`).
2. Captura de `docker-compose ps` con los 3 contenedores.
3. Postman mostrando una petición exitosa (ej. `GET /api/tasks`).
4. URL de Render funcionando (`https://todo-api.onrender.com/api/tasks`).