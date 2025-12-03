package com.ecomarket.presentation.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/database")
@RequiredArgsConstructor
public class DatabaseController {

    private final JdbcTemplate jdbcTemplate;

    @PostMapping("/update-images")
    public ResponseEntity<Map<String, Object>> updateProductImages() {
        Map<String, Object> response = new HashMap<>();
        int updatedCount = 0;

        try {
            // Actualizar productos con las imágenes disponibles
            updatedCount += jdbcTemplate.update(
                "UPDATE products SET image_filename = ? WHERE name = ?",
                "mochila.png", "Mochila Ecológica"
            );
            
            updatedCount += jdbcTemplate.update(
                "UPDATE products SET image_filename = ? WHERE name = ?",
                "mesa.png", "Mesa de Material Reciclado"
            );
            
            updatedCount += jdbcTemplate.update(
                "UPDATE products SET image_filename = ? WHERE name = ?",
                "bolsa.png", "Bolsa Reutilizable"
            );
            
            updatedCount += jdbcTemplate.update(
                "UPDATE products SET image_filename = ? WHERE name = ?",
                "cubiertos.png", "Set de Cubiertos de Bambú"
            );
            
            updatedCount += jdbcTemplate.update(
                "UPDATE products SET image_filename = ? WHERE name = ?",
                "lampara.png", "Lámpara Solar Reciclada"
            );
            
            updatedCount += jdbcTemplate.update(
                "UPDATE products SET image_filename = ? WHERE name = ?",
                "tapete.png", "Tapete de Yoga Ecológico"
            );
            
            updatedCount += jdbcTemplate.update(
                "UPDATE products SET image_filename = ? WHERE name = ?",
                "estante.png", "Estante de Madera Reciclada"
            );

            response.put("success", true);
            response.put("message", "Imágenes actualizadas exitosamente");
            response.put("updatedProducts", updatedCount);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error al actualizar imágenes: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @GetMapping("/verify-images")
    public ResponseEntity<Map<String, Object>> verifyImages() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            var products = jdbcTemplate.queryForList(
                "SELECT name, image_filename FROM products ORDER BY id"
            );
            
            response.put("success", true);
            response.put("products", products);
            response.put("totalProducts", products.size());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
