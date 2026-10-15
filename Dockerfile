
# ==========================================
# WAO WEB - DOCKERFILE PARA RAILWAY
# ==========================================

# ETAPA 1: Compilar Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Instalar dependencias
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el proyecto
COPY . .

# Compilar Flutter para producción
RUN flutter build web --release

# ETAPA 2: Servidor Nginx
FROM nginx:alpine

# Copiar la aplicación compilada
COPY --from=build /app/build/web /usr/share/nginx/html

# Configuración para Railway
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Puerto del servidor
EXPOSE 8080
