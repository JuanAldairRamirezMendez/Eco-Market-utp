package com.ecomarket.infrastructure.persistence.mapper;

import com.ecomarket.domain.model.Role;
import com.ecomarket.domain.model.User;
import com.ecomarket.infrastructure.persistence.entity.RoleEntity;
import com.ecomarket.infrastructure.persistence.entity.UserEntity;
import java.util.LinkedHashSet;
import java.util.Set;
import javax.annotation.processing.Generated;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-03T00:35:37-0500",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 22.0.1 (Oracle Corporation)"
)
@Component
public class UserEntityMapperImpl implements UserEntityMapper {

    @Autowired
    private RoleEntityMapper roleEntityMapper;

    @Override
    public User toDomain(UserEntity entity) {
        if ( entity == null ) {
            return null;
        }

        User.UserBuilder user = User.builder();

        user.id( entity.getId() );
        user.username( entity.getUsername() );
        user.email( entity.getEmail() );
        user.password( entity.getPassword() );
        user.firstName( entity.getFirstName() );
        user.lastName( entity.getLastName() );
        user.phone( entity.getPhone() );
        user.address( entity.getAddress() );
        user.isActive( entity.getIsActive() );
        user.roles( roleEntitySetToRoleSet( entity.getRoles() ) );
        user.createdAt( entity.getCreatedAt() );
        user.updatedAt( entity.getUpdatedAt() );

        return user.build();
    }

    @Override
    public UserEntity toEntity(User domain) {
        if ( domain == null ) {
            return null;
        }

        UserEntity.UserEntityBuilder userEntity = UserEntity.builder();

        userEntity.id( domain.getId() );
        userEntity.username( domain.getUsername() );
        userEntity.email( domain.getEmail() );
        userEntity.password( domain.getPassword() );
        userEntity.firstName( domain.getFirstName() );
        userEntity.lastName( domain.getLastName() );
        userEntity.phone( domain.getPhone() );
        userEntity.address( domain.getAddress() );
        userEntity.isActive( domain.getIsActive() );
        userEntity.roles( roleSetToRoleEntitySet( domain.getRoles() ) );
        userEntity.createdAt( domain.getCreatedAt() );
        userEntity.updatedAt( domain.getUpdatedAt() );

        return userEntity.build();
    }

    protected Set<Role> roleEntitySetToRoleSet(Set<RoleEntity> set) {
        if ( set == null ) {
            return null;
        }

        Set<Role> set1 = new LinkedHashSet<Role>( Math.max( (int) ( set.size() / .75f ) + 1, 16 ) );
        for ( RoleEntity roleEntity : set ) {
            set1.add( roleEntityMapper.toDomain( roleEntity ) );
        }

        return set1;
    }

    protected Set<RoleEntity> roleSetToRoleEntitySet(Set<Role> set) {
        if ( set == null ) {
            return null;
        }

        Set<RoleEntity> set1 = new LinkedHashSet<RoleEntity>( Math.max( (int) ( set.size() / .75f ) + 1, 16 ) );
        for ( Role role : set ) {
            set1.add( roleEntityMapper.toEntity( role ) );
        }

        return set1;
    }
}
