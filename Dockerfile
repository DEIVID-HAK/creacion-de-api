# Dockerfile para la API de Tareas (Node.js + Express)
FROM node:20-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias (incluye dev para el modo "dev" con nodemon)
RUN npm install

# Copiar el codigo fuente
COPY src/ ./src/

# Exponer el puerto
EXPOSE 3000

# Comando de inicio
CMD ["npm", "start"]