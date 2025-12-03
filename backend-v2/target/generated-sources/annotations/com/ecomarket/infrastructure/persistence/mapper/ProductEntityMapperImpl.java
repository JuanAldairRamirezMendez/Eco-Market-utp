package com.ecomarket.infrastructure.persistence.mapper;

import com.ecomarket.domain.model.Product;
import com.ecomarket.infrastructure.persistence.entity.ProductEntity;
import javax.annotation.processing.Generated;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-03T00:35:37-0500",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 22.0.1 (Oracle Corporation)"
)
@Component
public class ProductEntityMapperImpl implements ProductEntityMapper {

    @Autowired
    private CategoryEntityMapper categoryEntityMapper;

    @Override
    public Product toDomain(ProductEntity entity) {
        if ( entity == null ) {
            return null;
        }

        Product.ProductBuilder product = Product.builder();

        product.id( entity.getId() );
        product.name( entity.getName() );
        product.description( entity.getDescription() );
        product.price( entity.getPrice() );
        product.stockQuantity( entity.getStockQuantity() );
        product.category( categoryEntityMapper.toDomain( entity.getCategory() ) );
        product.imageFilename( entity.getImageFilename() );
        product.isOrganic( entity.getIsOrganic() );
        product.certifications( entity.getCertifications() );
        product.originCountry( entity.getOriginCountry() );
        product.carbonFootprint( entity.getCarbonFootprint() );
        product.isActive( entity.getIsActive() );
        product.isFeatured( entity.getIsFeatured() );
        product.createdAt( entity.getCreatedAt() );
        product.updatedAt( entity.getUpdatedAt() );

        return product.build();
    }

    @Override
    public ProductEntity toEntity(Product domain) {
        if ( domain == null ) {
            return null;
        }

        ProductEntity.ProductEntityBuilder productEntity = ProductEntity.builder();

        productEntity.id( domain.getId() );
        productEntity.name( domain.getName() );
        productEntity.description( domain.getDescription() );
        productEntity.price( domain.getPrice() );
        productEntity.stockQuantity( domain.getStockQuantity() );
        productEntity.category( categoryEntityMapper.toEntity( domain.getCategory() ) );
        productEntity.imageFilename( domain.getImageFilename() );
        productEntity.isOrganic( domain.getIsOrganic() );
        productEntity.certifications( domain.getCertifications() );
        productEntity.originCountry( domain.getOriginCountry() );
        productEntity.carbonFootprint( domain.getCarbonFootprint() );
        productEntity.isActive( domain.getIsActive() );
        productEntity.isFeatured( domain.getIsFeatured() );
        productEntity.createdAt( domain.getCreatedAt() );
        productEntity.updatedAt( domain.getUpdatedAt() );

        return productEntity.build();
    }
}
