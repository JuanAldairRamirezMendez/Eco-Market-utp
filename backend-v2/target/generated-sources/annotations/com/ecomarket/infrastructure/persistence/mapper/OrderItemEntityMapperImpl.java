package com.ecomarket.infrastructure.persistence.mapper;

import com.ecomarket.domain.model.Order;
import com.ecomarket.domain.model.OrderItem;
import com.ecomarket.domain.model.Role;
import com.ecomarket.domain.model.User;
import com.ecomarket.infrastructure.persistence.entity.OrderEntity;
import com.ecomarket.infrastructure.persistence.entity.OrderItemEntity;
import com.ecomarket.infrastructure.persistence.entity.RoleEntity;
import com.ecomarket.infrastructure.persistence.entity.UserEntity;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
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
public class OrderItemEntityMapperImpl implements OrderItemEntityMapper {

    @Autowired
    private ProductEntityMapper productEntityMapper;

    @Override
    public OrderItem toDomain(OrderItemEntity entity) {
        if ( entity == null ) {
            return null;
        }

        OrderItem.OrderItemBuilder orderItem = OrderItem.builder();

        orderItem.id( entity.getId() );
        orderItem.order( orderEntityToOrder( entity.getOrder() ) );
        orderItem.product( productEntityMapper.toDomain( entity.getProduct() ) );
        orderItem.quantity( entity.getQuantity() );
        orderItem.unitPrice( entity.getUnitPrice() );
        orderItem.totalPrice( entity.getTotalPrice() );

        return orderItem.build();
    }

    @Override
    public OrderItemEntity toEntity(OrderItem domain) {
        if ( domain == null ) {
            return null;
        }

        OrderItemEntity.OrderItemEntityBuilder orderItemEntity = OrderItemEntity.builder();

        orderItemEntity.id( domain.getId() );
        orderItemEntity.order( orderToOrderEntity( domain.getOrder() ) );
        orderItemEntity.product( productEntityMapper.toEntity( domain.getProduct() ) );
        orderItemEntity.quantity( domain.getQuantity() );
        orderItemEntity.unitPrice( domain.getUnitPrice() );
        orderItemEntity.totalPrice( domain.getTotalPrice() );

        return orderItemEntity.build();
    }

    protected Role roleEntityToRole(RoleEntity roleEntity) {
        if ( roleEntity == null ) {
            return null;
        }

        Role.RoleBuilder role = Role.builder();

        role.id( roleEntity.getId() );
        role.name( roleEntity.getName() );
        role.description( roleEntity.getDescription() );

        return role.build();
    }

    protected Set<Role> roleEntitySetToRoleSet(Set<RoleEntity> set) {
        if ( set == null ) {
            return null;
        }

        Set<Role> set1 = new LinkedHashSet<Role>( Math.max( (int) ( set.size() / .75f ) + 1, 16 ) );
        for ( RoleEntity roleEntity : set ) {
            set1.add( roleEntityToRole( roleEntity ) );
        }

        return set1;
    }

    protected User userEntityToUser(UserEntity userEntity) {
        if ( userEntity == null ) {
            return null;
        }

        User.UserBuilder user = User.builder();

        user.id( userEntity.getId() );
        user.username( userEntity.getUsername() );
        user.email( userEntity.getEmail() );
        user.password( userEntity.getPassword() );
        user.firstName( userEntity.getFirstName() );
        user.lastName( userEntity.getLastName() );
        user.phone( userEntity.getPhone() );
        user.address( userEntity.getAddress() );
        user.isActive( userEntity.getIsActive() );
        user.roles( roleEntitySetToRoleSet( userEntity.getRoles() ) );
        user.createdAt( userEntity.getCreatedAt() );
        user.updatedAt( userEntity.getUpdatedAt() );

        return user.build();
    }

    protected List<OrderItem> orderItemEntityListToOrderItemList(List<OrderItemEntity> list) {
        if ( list == null ) {
            return null;
        }

        List<OrderItem> list1 = new ArrayList<OrderItem>( list.size() );
        for ( OrderItemEntity orderItemEntity : list ) {
            list1.add( toDomain( orderItemEntity ) );
        }

        return list1;
    }

    protected Order orderEntityToOrder(OrderEntity orderEntity) {
        if ( orderEntity == null ) {
            return null;
        }

        Order.OrderBuilder order = Order.builder();

        order.id( orderEntity.getId() );
        order.user( userEntityToUser( orderEntity.getUser() ) );
        order.orderItems( orderItemEntityListToOrderItemList( orderEntity.getOrderItems() ) );
        order.totalAmount( orderEntity.getTotalAmount() );
        if ( orderEntity.getStatus() != null ) {
            order.status( Enum.valueOf( Order.OrderStatus.class, orderEntity.getStatus() ) );
        }
        order.shippingAddress( orderEntity.getShippingAddress() );
        order.billingAddress( orderEntity.getBillingAddress() );
        order.paymentMethod( orderEntity.getPaymentMethod() );
        order.paymentStatus( orderEntity.getPaymentStatus() );
        order.trackingNumber( orderEntity.getTrackingNumber() );
        order.notes( orderEntity.getNotes() );
        order.createdAt( orderEntity.getCreatedAt() );
        order.updatedAt( orderEntity.getUpdatedAt() );

        return order.build();
    }

    protected RoleEntity roleToRoleEntity(Role role) {
        if ( role == null ) {
            return null;
        }

        RoleEntity.RoleEntityBuilder roleEntity = RoleEntity.builder();

        roleEntity.id( role.getId() );
        roleEntity.name( role.getName() );
        roleEntity.description( role.getDescription() );

        return roleEntity.build();
    }

    protected Set<RoleEntity> roleSetToRoleEntitySet(Set<Role> set) {
        if ( set == null ) {
            return null;
        }

        Set<RoleEntity> set1 = new LinkedHashSet<RoleEntity>( Math.max( (int) ( set.size() / .75f ) + 1, 16 ) );
        for ( Role role : set ) {
            set1.add( roleToRoleEntity( role ) );
        }

        return set1;
    }

    protected UserEntity userToUserEntity(User user) {
        if ( user == null ) {
            return null;
        }

        UserEntity.UserEntityBuilder userEntity = UserEntity.builder();

        userEntity.id( user.getId() );
        userEntity.username( user.getUsername() );
        userEntity.email( user.getEmail() );
        userEntity.password( user.getPassword() );
        userEntity.firstName( user.getFirstName() );
        userEntity.lastName( user.getLastName() );
        userEntity.phone( user.getPhone() );
        userEntity.address( user.getAddress() );
        userEntity.isActive( user.getIsActive() );
        userEntity.roles( roleSetToRoleEntitySet( user.getRoles() ) );
        userEntity.createdAt( user.getCreatedAt() );
        userEntity.updatedAt( user.getUpdatedAt() );

        return userEntity.build();
    }

    protected List<OrderItemEntity> orderItemListToOrderItemEntityList(List<OrderItem> list) {
        if ( list == null ) {
            return null;
        }

        List<OrderItemEntity> list1 = new ArrayList<OrderItemEntity>( list.size() );
        for ( OrderItem orderItem : list ) {
            list1.add( toEntity( orderItem ) );
        }

        return list1;
    }

    protected OrderEntity orderToOrderEntity(Order order) {
        if ( order == null ) {
            return null;
        }

        OrderEntity.OrderEntityBuilder orderEntity = OrderEntity.builder();

        orderEntity.id( order.getId() );
        orderEntity.user( userToUserEntity( order.getUser() ) );
        orderEntity.orderItems( orderItemListToOrderItemEntityList( order.getOrderItems() ) );
        orderEntity.totalAmount( order.getTotalAmount() );
        if ( order.getStatus() != null ) {
            orderEntity.status( order.getStatus().name() );
        }
        orderEntity.shippingAddress( order.getShippingAddress() );
        orderEntity.billingAddress( order.getBillingAddress() );
        orderEntity.paymentMethod( order.getPaymentMethod() );
        orderEntity.paymentStatus( order.getPaymentStatus() );
        orderEntity.trackingNumber( order.getTrackingNumber() );
        orderEntity.notes( order.getNotes() );
        orderEntity.createdAt( order.getCreatedAt() );
        orderEntity.updatedAt( order.getUpdatedAt() );

        return orderEntity.build();
    }
}
