package com.ecomarket.presentation.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Controlador para servir imágenes estáticas
 */
@RestController
@RequestMapping("/images")
@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:3000"})
public class ImageController {

    @Value("${file.upload-dir}")
    private String uploadDir;

    @Value("${aws.s3.enabled:false}")
    private boolean s3Enabled;

    @Value("${aws.s3.bucket-name:}")
    private String bucketName;

    @GetMapping("/{filename:.+}")
    public ResponseEntity<?> getImage(@PathVariable String filename) {
        // Si S3 está habilitado, redireccionar a S3
        if (s3Enabled && !bucketName.isEmpty()) {
            String s3Url = String.format("https://%s.s3.us-east-1.amazonaws.com/products/%s", 
                                       bucketName, filename);
            return ResponseEntity.status(HttpStatus.FOUND)
                    .location(URI.create(s3Url))
                    .build();
        }

        // Si S3 no está habilitado, servir desde local
        try {
            Path filePath = Paths.get(uploadDir).resolve(filename).normalize();
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() && resource.isReadable()) {
                String contentType = determineContentType(filename);
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    private String determineContentType(String filename) {
        String extension = filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
        return switch (extension) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png" -> "image/png";
            case "gif" -> "image/gif";
            case "webp" -> "image/webp";
            case "svg" -> "image/svg+xml";
            default -> "application/octet-stream";
        };
    }
}
