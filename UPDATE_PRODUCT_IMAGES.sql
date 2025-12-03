-- ✅ Script SQL para actualizar las imágenes de los productos
-- Ejecutar en H2 Console: http://localhost:8080/ecomarket/api/h2-console
-- JDBC URL: jdbc:h2:mem:ecomarket
-- User: sa
-- Password: (vacío)

-- ✅ Imágenes detectadas en uploads/products/:
-- mochila.png, mesa.png, bolsa.png, cubiertos.png, lampara.png, tapete.png, estante.png

-- Actualizar productos con las imágenes:

-- Producto 1: Mochila Ecológica
UPDATE products SET image_filename = 'mochila.png' WHERE name = 'Mochila Ecológica';

-- Producto 2: Mesa de Material Reciclado
UPDATE products SET image_filename = 'mesa.png' WHERE name = 'Mesa de Material Reciclado';

-- Producto 3: Bolsa Reutilizable
UPDATE products SET image_filename = 'bolsa.png' WHERE name = 'Bolsa Reutilizable';

-- Producto 4: Silla Reciclada (sin imagen disponible, mantener null)
-- UPDATE products SET image_filename = 'silla.png' WHERE name = 'Silla Reciclada';

-- Producto 5: Set de Cubiertos de Bambú
UPDATE products SET image_filename = 'cubiertos.png' WHERE name = 'Set de Cubiertos de Bambú';

-- Producto 6: Lámpara Solar Reciclada
UPDATE products SET image_filename = 'lampara.png' WHERE name = 'Lámpara Solar Reciclada';

-- Producto 7: Tapete de Yoga Ecológico
UPDATE products SET image_filename = 'tapete.png' WHERE name = 'Tapete de Yoga Ecológico';

-- Producto 8: Estante de Madera Reciclada
UPDATE products SET image_filename = 'estante.png' WHERE name = 'Estante de Madera Reciclada';

-- Verificar los cambios:
SELECT id, name, image_filename FROM products ORDER BY id;

-- ✅ URLs de las imágenes:
-- http://localhost:8080/ecomarket/api/images/mochila.png
-- http://localhost:8080/ecomarket/api/images/mesa.png
-- http://localhost:8080/ecomarket/api/images/bolsa.png
-- http://localhost:8080/ecomarket/api/images/cubiertos.png
-- http://localhost:8080/ecomarket/api/images/lampara.png
-- http://localhost:8080/ecomarket/api/images/tapete.png
-- http://localhost:8080/ecomarket/api/images/estante.png
