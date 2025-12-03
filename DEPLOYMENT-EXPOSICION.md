# 🚀 Deployment Rápido para Exposición Universitaria

## Opción 1: Railway (Más Fácil - RECOMENDADO)

### ¿Por qué Railway?
- ✅ **GRATIS**: $5 de crédito gratis cada mes
- ✅ **FÁCIL**: Solo conectas tu GitHub
- ✅ **RÁPIDO**: Deploy en 2 minutos
- ✅ **URL automática**: Te da una URL pública al instante

### Pasos:

1. **Sube tu código a GitHub** (parece que ya lo tienes)

2. **Ve a Railway.app**
   - Crea cuenta con GitHub
   - New Project → Deploy from GitHub
   - Selecciona tu repo `EcoMarket-utp`

3. **Configura variables de ambiente:**
   ```
   SPRING_PROFILES_ACTIVE=production
   JWT_SECRET=tu_jwt_secret_aqui
   SPRING_DATASOURCE_URL=postgresql_url_que_te_da_railway
   ```

4. **¡Listo!** Te da una URL como: `https://ecomarket-production.up.railway.app`

---

## Opción 2: Render (También Gratis)

1. **Ve a Render.com**
2. **Connect GitHub**
3. **Deploy Spring Boot app**
4. **Configura PostgreSQL gratis**

---

## Opción 3: Heroku (Clásico)

1. **Instala Heroku CLI**
2. **heroku create ecomarket-tu-nombre**
3. **git push heroku main**

---

## Para tu exposición necesitas:

### 1. Crear archivo Procfile (para Heroku/Railway):
```
web: java -Dserver.port=$PORT -jar target/backend-v2-1.0.0.jar
```

### 2. Configurar application-production.properties:
```properties
server.port=${PORT:8080}
spring.datasource.url=${DATABASE_URL}
spring.jpa.hibernate.ddl-auto=update
```

¿Cuál prefieres? **Te recomiendo Railway porque es súper fácil para exposiciones.**