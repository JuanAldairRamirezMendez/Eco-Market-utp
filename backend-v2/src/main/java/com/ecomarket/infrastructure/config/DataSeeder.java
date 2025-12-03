package com.ecomarket.infrastructure.config;

import com.ecomarket.domain.model.Category;
import com.ecomarket.domain.model.Product;
import com.ecomarket.domain.model.Role;
import com.ecomarket.domain.model.User;
import com.ecomarket.domain.repository.CategoryRepository;
import com.ecomarket.domain.repository.ProductRepository;
import com.ecomarket.domain.repository.RoleRepository;
import com.ecomarket.domain.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;

/**
 * DataSeeder para datos iniciales con arquitectura DDD
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {
    
    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final PasswordEncoder passwordEncoder;
    
    @Override
    @Transactional
    public void run(String... args) {
        log.info("=== Starting DataSeeder ===");
        
        seedRoles();
        seedUsers();
        seedCategories();
        seedProducts();
        
        log.info("=== DataSeeder completed successfully ===");
    }
    
    private void seedRoles() {
        if (roleRepository.existsByName(Role.ADMIN)) {
            log.info("Roles already exist, skipping...");
            return;
        }
        
        log.info("Creating roles...");
        
        Role adminRole = Role.builder()
                .name(Role.ADMIN)
                .description("Administrator role")
                .build();
        roleRepository.save(adminRole);
        
        Role userRole = Role.builder()
                .name(Role.USER)
                .description("User role")
                .build();
        roleRepository.save(userRole);
        
        log.info("Roles created: ADMIN, USER");
    }
    
    private void seedUsers() {
        if (userRepository.existsByUsername("admin")) {
            log.info("Users already exist, skipping...");
            return;
        }
        
        log.info("Creating users...");
        
        Role adminRole = roleRepository.findByName(Role.ADMIN).orElseThrow();
        Role userRole = roleRepository.findByName(Role.USER).orElseThrow();
        
        // Admin user
        User admin = User.builder()
                .username("admin")
                .email("admin@ecomarket.com")
                .password(passwordEncoder.encode("admin123"))
                .firstName("Admin")
                .lastName("EcoMarket")
                .isActive(true)
                .roles(new HashSet<>())
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        admin.addRole(adminRole);
        userRepository.save(admin);
        
        // Regular user
        User user = User.builder()
                .username("user")
                .email("user@ecomarket.com")
                .password(passwordEncoder.encode("user123"))
                .firstName("Juan")
                .lastName("Pérez")
                .phone("+51 987 654 321")
                .address("Av. Principal 123, Lima")
                .isActive(true)
                .roles(new HashSet<>())
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        user.addRole(userRole);
        userRepository.save(user);
        
        log.info("Users created: admin, user");
    }
    
    private void seedCategories() {
        if (categoryRepository.existsByName("Muebles Ecológicos")) {
            log.info("Categories already exist, skipping...");
            return;
        }
        
        log.info("Creating categories...");
        
        Category furniture = Category.builder()
                .name("Muebles Ecológicos")
                .description("Muebles fabricados con materiales reciclados y sostenibles")
                .imageUrl("/assets/categories/furniture.jpg")
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        categoryRepository.save(furniture);
        
        Category accessories = Category.builder()
                .name("Accesorios Sostenibles")
                .description("Accesorios eco-friendly para el día a día")
                .imageUrl("/assets/categories/accessories.jpg")
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        categoryRepository.save(accessories);
        
        Category home = Category.builder()
                .name("Hogar Eco-Friendly")
                .description("Productos sustentables para tu hogar")
                .imageUrl("/assets/categories/home.jpg")
                .isActive(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        categoryRepository.save(home);
        
        log.info("Categories created: 3");
    }
    
    private void seedProducts() {
        if (productRepository.existsByName("Mochila Ecológica")) {
            log.info("Products already exist, skipping...");
            return;
        }
        
        log.info("Creating products...");
        
        Category furniture = categoryRepository.findByName("Muebles Ecológicos").orElseThrow();
        Category accessories = categoryRepository.findByName("Accesorios Sostenibles").orElseThrow();
        Category home = categoryRepository.findByName("Hogar Eco-Friendly").orElseThrow();
        
        // Producto 1: Mochila Ecológica
        Product backpack = Product.builder()
                .name("Mochila Ecológica")
                .description("Mochila fabricada con materiales reciclados 100% sustentables. Diseño moderno y espacioso.")
                .price(new BigDecimal("89.90"))
                .stockQuantity(35)
                .category(accessories)
                .imageFilename("mochila.png")
                .isOrganic(true)
                .certifications("Certificación Global Recycled Standard (GRS)")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("2.5"))
                .isActive(true)
                .isFeatured(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(backpack);
        
        // Producto 2: Mesa de Material Reciclado
        Product table = Product.builder()
                .name("Mesa de Material Reciclado")
                .description("Mesa elegante fabricada con madera reciclada. Perfecta para comedor o sala.")
                .price(new BigDecimal("450.00"))
                .stockQuantity(12)
                .category(furniture)
                .imageFilename("mesa.png")
                .isOrganic(false)
                .certifications("FSC Recycled, ISO 14001")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("15.8"))
                .isActive(true)
                .isFeatured(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(table);
        
        // Producto 3: Bolsa Reutilizable
        Product bag = Product.builder()
                .name("Bolsa Reutilizable")
                .description("Bolsa de tela orgánica reutilizable. Resistente y lavable.")
                .price(new BigDecimal("15.50"))
                .stockQuantity(120)
                .category(accessories)
                .imageFilename("bolsa.png")
                .isOrganic(true)
                .certifications("GOTS (Global Organic Textile Standard)")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("0.8"))
                .isActive(true)
                .isFeatured(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(bag);
        
        // Producto 4: Silla Reciclada
        Product chair = Product.builder()
                .name("Silla Reciclada")
                .description("Silla moderna fabricada con plástico reciclado del océano.")
                .price(new BigDecimal("180.00"))
                .stockQuantity(28)
                .category(furniture)
                .imageFilename(null)
                .isOrganic(false)
                .certifications("Ocean Plastic Certified, Cradle to Cradle")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("8.5"))
                .isActive(true)
                .isFeatured(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(chair);
        
        // Producto 5: Set de Cubiertos de Bambú
        Product cutlery = Product.builder()
                .name("Set de Cubiertos de Bambú")
                .description("Set de cubiertos ecológicos de bambú. Incluye estuche de transporte.")
                .price(new BigDecimal("25.90"))
                .stockQuantity(85)
                .category(home)
                .imageFilename("cubiertos.png")
                .isOrganic(true)
                .certifications("FSC 100%, Biodegradable")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("1.2"))
                .isActive(true)
                .isFeatured(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(cutlery);
        
        // Producto 6: Lámpara Solar Reciclada
        Product lamp = Product.builder()
                .name("Lámpara Solar Reciclada")
                .description("Lámpara solar portátil fabricada con materiales reciclados.")
                .price(new BigDecimal("95.00"))
                .stockQuantity(42)
                .category(home)
                .imageFilename("lampara.png")
                .isOrganic(false)
                .certifications("Energy Star, RoHS Compliant")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("3.8"))
                .isActive(true)
                .isFeatured(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(lamp);
        
        // Producto 7: Tapete de Yoga Ecológico
        Product yogaMat = Product.builder()
                .name("Tapete de Yoga Ecológico")
                .description("Tapete de yoga fabricado con caucho natural y materiales biodegradables.")
                .price(new BigDecimal("75.00"))
                .stockQuantity(50)
                .category(accessories)
                .imageFilename("tapete.png")
                .isOrganic(true)
                .certifications("Oeko-Tex Standard 100, Biodegradable")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("4.2"))
                .isActive(true)
                .isFeatured(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(yogaMat);
        
        // Producto 8: Estante de Madera Reciclada
        Product bookshelf = Product.builder()
                .name("Estante de Madera Reciclada")
                .description("Estante minimalista de madera recuperada. Ideal para libros y decoración.")
                .price(new BigDecimal("320.00"))
                .stockQuantity(18)
                .category(furniture)
                .imageFilename("estante.png")
                .isOrganic(false)
                .certifications("FSC Recycled, Upcycled Certified")
                .originCountry("Perú")
                .carbonFootprint(new BigDecimal("12.3"))
                .isActive(true)
                .isFeatured(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
        productRepository.save(bookshelf);
        
        log.info("Products created: 8 eco-friendly products");
    }
}
