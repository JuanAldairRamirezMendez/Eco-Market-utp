package com.ecomarket.infrastructure.persistence.mapper;

import com.ecomarket.domain.model.Category;
import com.ecomarket.infrastructure.persistence.entity.CategoryEntity;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-03T00:35:37-0500",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 22.0.1 (Oracle Corporation)"
)
@Component
public class CategoryEntityMapperImpl implements CategoryEntityMapper {

    @Override
    public Category toDomain(CategoryEntity entity) {
        if ( entity == null ) {
            return null;
        }

        Category.CategoryBuilder category = Category.builder();

        category.id( entity.getId() );
        category.name( entity.getName() );
        category.description( entity.getDescription() );
        category.imageUrl( entity.getImageUrl() );
        category.isActive( entity.getIsActive() );
        category.createdAt( entity.getCreatedAt() );
        category.updatedAt( entity.getUpdatedAt() );

        return category.build();
    }

    @Override
    public CategoryEntity toEntity(Category domain) {
        if ( domain == null ) {
            return null;
        }

        CategoryEntity.CategoryEntityBuilder categoryEntity = CategoryEntity.builder();

        categoryEntity.id( domain.getId() );
        categoryEntity.name( domain.getName() );
        categoryEntity.description( domain.getDescription() );
        categoryEntity.imageUrl( domain.getImageUrl() );
        categoryEntity.isActive( domain.getIsActive() );
        categoryEntity.createdAt( domain.getCreatedAt() );
        categoryEntity.updatedAt( domain.getUpdatedAt() );

        return categoryEntity.build();
    }
}
