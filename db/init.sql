-- Esquema de la base de datos para la API de tareas
-- Se ejecuta automaticamente la primera vez con docker-compose
-- (montado en /docker-entrypoint-initdb.d/ de la imagen postgres).

CREATE TABLE IF NOT EXISTS tasks (
  id          SERIAL PRIMARY KEY,
  title       TEXT NOT NULL,
  description TEXT,
  completed   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Datos de prueba opcionales
INSERT INTO tasks (title, description) VALUES
  ('Primera tarea', 'Creada desde init.sql'),
  ('Segunda tarea', 'Probar el GET de la API');