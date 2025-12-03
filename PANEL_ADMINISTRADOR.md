# Panel de Administrador - EcoMarket

## 🎯 Acceso al Panel

El panel de administrador está completamente funcional y te permite gestionar los productos de EcoMarket.

### Credenciales de Administrador

**Usuario:** `admin`  
**Contraseña:** `admin123`

### URL de Acceso

Una vez que inicies sesión como administrador, verás un enlace **"⚙️ Panel Admin"** en la barra de navegación superior.

También puedes acceder directamente a través de estas rutas:

- **Dashboard Principal:** `http://localhost:4200/admin/dashboard`
- **Gestión de Productos:** `http://localhost:4200/admin/products`
- **Agregar Nuevo Producto:** `http://localhost:4200/admin/products/new`
- **Editar Producto:** `http://localhost:4200/admin/products/:id/edit`

## 📋 Funcionalidades del Panel

### 1. Dashboard de Administrador
- Visualización de estadísticas generales:
  - Total de productos
  - Total de usuarios
  - Total de pedidos
  - Ingresos totales
- Actividades recientes del sistema

### 2. Gestión de Productos
- **Lista de productos:** Ver todos los productos registrados
- **Búsqueda:** Filtrar productos por nombre
- **Filtrado por categoría:** Mostrar productos de una categoría específica
- **Agregar producto:** Crear nuevos productos con:
  - Nombre
  - Descripción
  - Precio
  - Categoría
  - Rating ecológico (1-5)
  - Puntuación de sostenibilidad (0-100)
  - Huella de carbono
  - Tags personalizados
  - Estado de disponibilidad
  - Imagen del producto
- **Editar producto:** Modificar información de productos existentes
- **Eliminar producto:** Remover productos del catálogo

### 3. Formulario de Producto
El formulario incluye validaciones para:
- Nombre: mínimo 3 caracteres, máximo 100
- Descripción: mínimo 10 caracteres, máximo 1000
- Precio: debe ser mayor a 0.01
- Rating ecológico: entre 1 y 5
- Puntuación de sostenibilidad: entre 0 y 100
- Huella de carbono: debe ser >= 0
- URL de imagen: formato válido (http/https)

## 🔐 Seguridad

El acceso al panel de administrador está protegido mediante:
1. **Autenticación JWT:** Solo usuarios autenticados pueden acceder
2. **Verificación de roles:** El enlace "Panel Admin" solo aparece si el usuario tiene el rol `ROLE_ADMIN`
3. **Guards de rutas:** (Puedes implementar guards adicionales en Angular para mayor seguridad)

## 📝 Notas Importantes

### Usuario Regular vs Administrador

**Usuario Regular (`user/user123`):**
- No ve el enlace "Panel Admin" en el navbar
- No tiene acceso a las rutas `/admin/*`
- Solo puede ver productos, agregar al carrito y realizar compras

**Administrador (`admin/admin123`):**
- Ve el enlace "⚙️ Panel Admin" en el navbar
- Tiene acceso completo al panel de administración
- Puede crear, editar y eliminar productos

### Categorías Disponibles
- Hogar Sostenible
- Moda Ecológica
- Alimentación Orgánica

### Tags Sugeridos
El formulario incluye tags predefinidos como:
- reciclado, ecológico, biodegradable, orgánico, vegano
- sostenible, reutilizable, certificado, natural, artesanal
- madera reciclada, plástico reciclado, cuero vegano
- algodón orgánico, acero inoxidable, etc.

## 🚀 Ejemplo de Uso

1. **Inicia el backend:**
   ```bash
   cd backend-v2
   java -jar target/backend-v2-1.0.0.jar
   ```

2. **Inicia el frontend:**
   ```bash
   cd frontend-angular
   npm run dev
   ```

3. **Accede a la aplicación:**
   - Abre `http://localhost:4200`
   - Haz clic en "Iniciar sesión"
   - Ingresa: `admin` / `admin123`
   - Verás el enlace "⚙️ Panel Admin" en la esquina superior derecha

4. **Gestiona productos:**
   - Haz clic en "Panel Admin"
   - Selecciona "Productos" o cualquier otra opción del menú
   - ¡Empieza a agregar, editar o eliminar productos!

## 🎨 Interfaz

El panel de administrador utiliza:
- **Tailwind CSS** para estilos modernos y responsivos
- **Componentes standalone de Angular 18**
- **Reactive Forms** para formularios con validación
- **Router de Angular** para navegación entre secciones
- **Iconos y emojis** para mejor UX

## 📞 Soporte

Si tienes alguna pregunta o necesitas ayuda adicional con el panel de administrador, no dudes en preguntar.
