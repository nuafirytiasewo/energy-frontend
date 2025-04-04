# 1. Используем официальный Node.js образ как базовый
FROM node:22.14.0-alpine AS build

# 2. Задаем рабочую директорию в контейнере
WORKDIR /src

# 3. Копируем package.json и package-lock.json в контейнер
COPY package*.json ./

# 4. Устанавливаем зависимости
RUN npm install

# 5. Копируем весь проект в контейнер
COPY . .

# Определяем аргумент для переменной окружения (значение придёт из CI/CD)
ARG REACT_APP_API_URL

# Устанавливаем переменную окружения из аргумента
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# Выводим переменные окружения для отладки
RUN echo "REACT_APP_API_URL during build: $REACT_APP_API_URL" > build-env.log

# 6. Собираем приложение для production, явно передавая переменную
RUN REACT_APP_API_URL=$REACT_APP_API_URL npm run build

# 7. Используем Nginx для запуска нашего приложения
FROM nginx:1.23-alpine
COPY --from=build /src/build /usr/share/nginx/html

# Временное решение для отладки
COPY --from=build /src/build-env.log /usr/share/nginx/html/build-env.log

# 8. Копируем пользовательскую конфигурацию Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 9. Экспонируем порт 80 для доступа к приложению
EXPOSE 80

# 10. Запускаем Nginx
CMD ["nginx", "-g", "daemon off;"]