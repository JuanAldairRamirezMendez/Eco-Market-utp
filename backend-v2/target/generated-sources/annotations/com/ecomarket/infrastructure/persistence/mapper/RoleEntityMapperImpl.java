package com.ecomarket.infrastructure.persistence.mapper;

import com.ecomarket.domain.model.Role;
import com.ecomarket.infrastructure.persistence.entity.RoleEntity;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-03T00:35:37-0500",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 22.0.1 (Oracle Corporation)"
)
@Component
public class RoleEntityMapperImpl implements RoleEntityMapper {

    @Override
    public Role toDomain(RoleEntity entity) {
        if ( entity == null ) {
            return null;
        }

        Role.RoleBuilder role = Role.builder();

        role.id( entity.getId() );
        role.name( entity.getName() );
        role.description( entity.getDescription() );

        return role.build();
    }

    @Override
    public RoleEntity toEntity(Role domain) {
        if ( domain == null ) {
            return null;
        }

        RoleEntity.RoleEntityBuilder roleEntity = RoleEntity.builder();

        roleEntity.id( domain.getId() );
        roleEntity.name( domain.getName() );
        roleEntity.description( domain.getDescription() );

        return roleEntity.build();
    }
}
