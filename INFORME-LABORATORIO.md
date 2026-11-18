# INFORME TÉCNICO DEL LABORATORIO
## Dockerización, Implantación y Despliegue de una API REST

---

### 1. Datos Generales

| Campo | Detalle |
|---|---|
| **Proyecto** | TODO API - Gestión de Tareas |
| **Autor** | David Vélez |
| **Institución** | SENA |
| **Materia** | Laboratorio |
| **Fecha** | 7 de septiembre de 2026 |
| **Duración** | 4-6 horas (2 sesiones) |
| **Nivel** | Intermedio |

---

### 2. Resumen Ejecutivo

En este laboratorio se construyó una **API REST de gestión de tareas (TODO)** desde cero, se contenerizó con **Docker**, se orquestaron tres servicios con **Docker Compose** (API, base de datos MongoDB y una interfaz gráfica de administración de BD) y se verificó el funcionamiento completo de la API realizando pruebas CRUD reales. El proyecto quedó versionado en **Git** y listo para su despliegue a producción en la nube.

---

### 3. Objetivos del Laboratorio

1. Crear una API REST funcional con almacenamiento en base de datos.
2. Escribir un `Dockerfile` para contenerizar la aplicación.
3. Orquestar múltiples servicios (app + base de datos) con `docker-compose.yml`.
4. Verificar el correcto funcionamiento de todos los endpoints mediante pruebas CRUD.
5. Versionar el proyecto con Git y documentar el proceso de implantación.

---

### 4. Marco Teórico (Conceptos Clave)

Para poder explicar este proyecto ante el maestro, es importante dominar estos conceptos:

- **API REST**: Interfaz de programación que permite a sistemas comunicarse vía HTTP usando métodos como GET (leer), POST (crear), PUT (actualizar) y DELETE (eliminar).
- **Docker**: Herramienta que empaqueta una aplicación y sus dependencias en una *imagen*, que luego se ejecuta en un *contenedor* aislado y reproducible en cualquier máquina.
- **Imagen vs Contenedor**: La imagen es la "plantilla" (receta), el contenedor es la instancia en ejecución.
- **Docker Compose**: Herramienta para definir y levantar **varios contenedores a la vez** (multi-servicio) con un solo archivo YAML.
- **MongoDB**: Base de datos NoSQL orientada a documentos (almacena datos tipo JSON).
- **Mongoose**: Biblioteca de Node.js que conecta la app con MongoDB y define el *modelo/estructura* de los datos.
- **Dockerfile**: Archivo con instrucciones paso a paso para construir una imagen.
- **Volumen Docker**: Espacio de almacenamiento persistente; los datos sobreviven aunque el contenedor se elimine.
- **Red bridge**: Red virtual local de Docker que permite que los contenedores se comuniquen entre sí por nombre.

---

### 5. Herramientas y Tecnologías Utilizadas

| Categoría | Herramienta | Versión |
|---|---|---|
| Lenguaje/Backend | Node.js + Express | Node 20 / Express 4 |
| Base de datos | MongoDB (con Mongoose) | MongoDB 6 |
| Contenerización | Docker / Docker Compose | Docker 29.x |
| Pruebas de API | Comandos HTTP / Postman | — |
| Versionado | Git | — |
| Editor | VS Code | — |

**¿Por qué Node.js y no Python/Flask?**
- La imagen Docker de Node (`node:20-alpine`) es mucho más liviana que la de Python.
- MongoDB se integra de forma nativa y muy simple con Node (Mongoose).
- Menos consumo de memoria y arranque más rápido para una API de este tipo.

---

### 6. Desarrollo Paso a Paso

#### Fase 1: Preparación del Entorno

Se creó la estructura del proyecto y se inicializó el repositorio Git:

```
proyecto-todo-api/
├── src/
│   └── index.js        ← Código de la aplicación
├── Dockerfile          ← Configuración de la imagen
├── docker-compose.yml  ← Orquestación de servicios
├── package.json        ← Dependencias y scripts de Node
├── .gitignore          ← Archivos excluidos del repositorio
└── README.md           ← Documentación del proyecto
```

```bash
git init                                                    # Inicializa el repositorio Git
echo "node_modules/" > .gitignore                           # Excluye node_modules
echo ".env" >> .gitignore                                   # Excluye variables de entorno
```

#### Fase 2: Desarrollo de la API REST (src/index.js)

Se creó una API REST completa con las siguientes **mejoras originales** respecto al ejemplo básico del laboratorio:

1. **Ruta adicional** `GET /api/tasks/:id` para consultar una tarea individual.
2. **Paginación y filtros**: `GET /api/tasks?completed=true&page=1&limit=5&sort=createdAt`.
3. **Validaciones en el modelo**: título obligatorio con mínimo 3 caracteres.
4. **Manejo de errores** estandarizado (códigos HTTP 201, 400, 404, 500).
5. **Middleware 404** para rutas no existentes.

**Estructura del código:**

```javascript
// 1. Dependencias e inicialización
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();
const app = express();
const PORT = process.env.PORT || 3000;

// 2. Middleware global
app.use(cors());
app.use(express.json());

// 3. Conexión a MongoDB (usa variable de entorno o valor por defecto)
mongoose.connect(process.env.MONGODB_URI || 'mongodb://mongodb:27017/tododb')

// 4. Modelo (esquema) de datos
const taskSchema = new mongoose.Schema({
  title: { type: String, required: [true, 'El título es obligatorio'], minlength: 3 },
  description: { type: String, default: '' },
  completed: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});
```

**Endpoints implementados:**

| Método HTTP | Ruta | Función | Código de éxito |
|---|---|---|---|
| GET | `/` | Mensaje de bienvenida | 200 |
| GET | `/api/tasks` | Listar tareas (con paginación/filtros) | 200 |
| GET | `/api/tasks/:id` | Obtener tarea por ID | 200 |
| POST | `/api/tasks` | Crear tarea | 201 |
| PUT | `/api/tasks/:id` | Actualizar tarea | 200 |
| DELETE | `/api/tasks/:id` | Eliminar tarea | 200 |

#### Fase 3: Dockerización (Dockerfile)

```dockerfile
FROM node:20-alpine        # Imagen base ligera (Node 20 sobre Alpine Linux)

WORKDIR /app               # Directorio de trabajo dentro del contenedor

COPY package*.json ./      # Copia lista de dependencias

RUN npm install --production   # Instala solo dependencias de producción

COPY src/ ./src/           # Copia el código fuente

EXPOSE 3000                # Documenta el puerto que usa la app

CMD ["npm", "start"]       # Comando que arranca el servidor
```

**Comando para construir la imagen:**
```bash
docker build -t todo-api:v1 .
```

#### Fase 4: Orquestación con Docker Compose

El `docker-compose.yml` levanta **tres servicios conectados en red propia**:

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│   MongoDB   │◄────│      API     │────►│  Mongo Express  │
│   (puerto   │     │   (puerto    │     │   (puerto 8081) │
│    27017)   │     │     3000)    │     │  Panel gráfico  │
└─────────────┘     └──────────────┘     └─────────────────┘
        └───────────── Red virtual "todo-network" ─────────────┘
```

**Explicación de cada servicio:**

1. **mongodb** (`mongo:6`): base de datos con credenciales de administrador, puerto 27017 y un **volumen** (`mongodb_data`) para que los datos sean persistentes.
2. **api** (construida desde nuestro Dockerfile): la aplicación Node, depende de MongoDB, expone el puerto 3000. Recibe la variable `MONGODB_URI` apuntando al servicio `mongodb` por su **nombre interno** (así funciona la red Docker).
3. **mongo-express**: interfaz web para administrar MongoDB gráficamente en http://localhost:8081.

```bash
docker-compose up -d    # Levanta los 3 servicios en segundo plano
docker-compose ps       # Muestra el estado de los contenedores
docker-compose logs api # Muestra los logs de la API
```

#### Fase 5: Pruebas de Funcionamiento (CRUD)

Se probaron todas las operaciones con resultados reales (evidencias en la sección 8). La API respondió correctamente a crear, listar, consultar por ID, actualizar y eliminar tareas.

#### Fase 6: Versionado con Git

```bash
git add .
git commit -m "API de Tareas lista para producción..."
```

Quedó excluido correctamente `node_modules/` y `.env` mediante `.gitignore`.

---

### 7. Problemas Encontrados y Soluciones

Durante el desarrollo surgieron dos inconvenientes reales, que son una valiosa evidencia de aprendizaje:

| # | Problema | Causa | Solución |
|---|---|---|---|
| 1 | El contenedor de la API no arrancaba (`Restarting 127`) | El `docker-compose.yml` usaba `command: npm run dev` (nodemon), pero la imagen instala solo dependencias de **producción** (`--production`), por lo que nodemon no existía | Se eliminó el comando de desarrollo del compose; la API corre en **modo producción** con `npm start`, que además es el modo que se usa en el despliegue real |
| 2 | Avisos de motor Node incompatible | La imagen base era `node:18-alpine`, pero la última versión de Mongoose exige Node 20+ | Se actualizó el Dockerfile a `node:20-alpine` |
| 3 | Docker Desktop no respondía | El daemon de Docker no estaba en ejecución | Se inició Docker Desktop y se esperó a que el motor estuviera listo |

---

### 8. Evidencias (Capturas de Resultados Reales)

> **Nota para el maestro:** Estas capturas se generaron directamente desde el navegador
> accediendo a la API en vivo y desde el estado real de Docker. También se pueden
> reemplazar por capturas tomadas en Postman.

#### 8.1 API funcionando en el navegador (endpoint raíz)

![API raíz](evidencias/api-root.png)

#### 8.2 API funcionando en el navegador (lista de tareas, JSON real)

![API lista de tareas](evidencias/api-en-vivo.png)

#### 8.3 Panel de evidencias con estado de contenedores, logs y resultados CRUD

![Evidencias CRUD y contenedores](evidencias/evidencias-crud.png)

#### 8.4 Estado de los contenedores
```
NAME                 STATUS
todo-api             Up 36 minutes
todo-mongo-express   Up 36 minutes
todo-mongodb         Up 36 minutes
```

#### 8.5 Logs de la API (conexión exitosa a la base de datos)
```
Servidor corriendo en http://localhost:3000
Conectado a MongoDB
```

#### 8.6 Prueba CRUD completa ejecutada

**POST /api/tasks** (crear tarea)
```json
{
  "title": "Mi primera tarea",
  "description": "Descripción de prueba",
  "completed": false,
  "_id": "6a9f03cd5c09a423826d0b15"
}
```

**GET /api/tasks** (listar, con paginación)
```json
{
  "total": 2,
  "page": 1,
  "limit": 10,
  "tasks": [ ... ]
}
```

**GET /api/tasks/:id** → devuelve la tarea individual ✅

**PUT /api/tasks/:id** → `"completed": false → true` ✅

**DELETE /api/tasks/:id** → `{"message": "Tarea eliminada"}` ✅

#### 8.7 Direcciones de acceso
- API: http://localhost:3000
- Panel MongoDB (Mongo Express): http://localhost:8081

---

### 9. Despliegue a Producción (Pendiente de ejecutar en sesión 2)

El proyecto quedó listo para subirse a la nube con Render + MongoDB Atlas:

1. Subir el repositorio a GitHub.
2. Crear un **Web Service** en render.com conectado al repositorio.
3. Configurar: Build `npm install`, Start `npm start`, plan gratuito.
4. Crear un cluster gratuito en MongoDB Atlas y copiar la URI de conexión.
5. Agregar variables de entorno en Render: `MONGODB_URI` y `PORT=10000`.
6. Render genera una URL pública tipo `https://todo-api.onrender.com`.

---

### 10. Conclusiones

1. **Se logró** construir una API REST completa y funcional con almacenamiento en MongoDB, superando el ejemplo base con paginación, filtros y validaciones.
2. **Se comprendió** el flujo completo de dockerización: escribir un Dockerfile, construir la imagen y ejecutar el contenedor.
3. **Se dominó** la orquestación multi-servicio con Docker Compose, incluyendo redes, volúmenes y dependencias entre contenedores.
4. **Se resolvieron** problemas reales e importantes: incompatibilidades de versiones de Node y modos de ejecución dev/producción, lo que demuestra comprensión del ecosistema Docker.
5. **Se dejó** la infraestructura preparada para producción, siguiendo buenas prácticas: variables de entorno, imagen optimizada y versionado con Git.

---

### 11. Anexos

**Comandos útiles para el maestro y futuras prácticas:**

```bash
# Construir la imagen manualmente
docker build -t todo-api:v1 .

# Levantar/derribar servicios
docker-compose up -d
docker-compose down            # Baja servicios (mantiene los datos del volumen)
docker-compose down -v         # Baja servicios Y borra los datos del volumen

# Inspeccionar
docker-compose ps              # Estado de contenedores
docker-compose logs -f api     # Logs en tiempo real de la API
docker ps                      # Lista contenedores activos
docker images                  # Lista imágenes locales
```

**Estructura final del repositorio:**
```
proyecto-todo-api/
├── .gitignore
├── Dockerfile
├── README.md
├── docker-compose.yml
├── package.json
├── package-lock.json
├── postman-collection.json        ← Colección de pruebas para Postman
├── evidencias/                    ← Capturas de pantalla del laboratorio
│   ├── api-root.png
│   ├── api-en-vivo.png
│   ├── evidencias-crud.png
│   └── evidencias.html
├── INFORME-LABORATORIO.md         ← Este informe
└── src/
    └── index.js
```