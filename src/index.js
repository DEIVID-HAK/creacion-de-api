const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Pool de conexiones a PostgreSQL.
// En Render usa una DATABASE_URL (postgres://usuario:pass@host:puerto/db),
// en local con docker-compose usa la conexion de desarrollo del .env.
const pool = new Pool({
  connectionString:
    process.env.DATABASE_URL ||
    process.env.POSTGRES_URL ||
    'postgres://todo:todo123@localhost:5432/tododb',
  ssl: process.env.PGSSL
    ? { rejectUnauthorized: false }
    : false
});

// Middleware
app.use(cors());
app.use(express.json());

// Crear la tabla si no existe (migracion basica al arrancar)
async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tasks (
      id          SERIAL PRIMARY KEY,
      title       TEXT NOT NULL,
      description TEXT,
      completed   BOOLEAN NOT NULL DEFAULT FALSE,
      created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
  console.log('Tabla "tasks" lista (PostgreSQL conectado)');
}

// Rutas
app.get('/', (req, res) => {
  res.json({ message: 'API de Tareas funcionando con PostgreSQL' });
});

app.get('/api/tasks', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, title, description, completed, created_at AS "createdAt" FROM tasks ORDER BY id'
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/tasks', async (req, res) => {
  try {
    const { title, description = '' } = req.body || {};
    if (!title || typeof title !== 'string') {
      return res.status(400).json({ error: 'El campo "title" es obligatorio' });
    }
    const result = await pool.query(
      'INSERT INTO tasks (title, description) VALUES ($1, $2) RETURNING id, title, description, completed, created_at AS "createdAt"',
      [title, description]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.put('/api/tasks/:id', async (req, res) => {
  try {
    const { title, description, completed } = req.body || {};
    const result = await pool.query(
      `UPDATE tasks
         SET title       = COALESCE($2, title),
             description = COALESCE($3, description),
             completed   = COALESCE($4, completed)
       WHERE id = $1
       RETURNING id, title, description, completed, created_at AS "createdAt"`,
      [req.params.id, title, description, completed]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM tasks WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }
    res.json({ message: 'Tarea eliminada' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Iniciar servidor
initDb()
  .catch((err) => {
    console.error('Error conectando a PostgreSQL:', err);
    process.exit(1);
  })
  .finally(() => {
    app.listen(PORT, () => {
      console.log(`Servidor corriendo en http://localhost:${PORT}`);
    });
  });