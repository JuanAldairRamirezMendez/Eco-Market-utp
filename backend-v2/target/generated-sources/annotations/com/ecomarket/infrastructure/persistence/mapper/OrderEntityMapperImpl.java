package com.ecomarket.infrastructure.persistence.mapper;

import com.ecomarket.domain.model.Order;
import com.ecomarket.domain.model.OrderItem;
import com.ecomarket.infrastructure.persistence.entity.OrderEntity;
import com.ecomarket.infrastructure.persistence.entity.OrderItemEntity;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.processing.Generated;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-12-03T00:35:37-0500",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 22.0.1 (Oracle Corporation)"
)
@Component
public class OrderEntityMapperImpl implements OrderEntityMapper {

    @Autowired
    private UserEntityMapper userEntityMapper;
    @Autowired
    private OrderItemEntityMapper orderItemEntityMapper;

    @Override
    public Order toDomain(OrderEntity entity) {
        if ( entity == null ) {
            return null;
        }

        Order.OrderBuilder order = Order.builder();

        order.status( stringToStatus( entity.getStatus() ) );
        order.id( entity.getId() );
        order.user( userEntityMapper.toDomain( entity.getUser() ) );
        order.orderItems( orderItemEntityListToOrderItemList( entity.getOrderItems() ) );
        order.totalAmount( entity.getTotalAmount() );
        order.shippingAddress( entity.getShippingAddress() );
        order.billingAddress( entity.getBillingAddress() );
        order.paymentMethod( entity.getPaymentMethod() );
        order.paymentStatus( entity.getPaymentStatus() );
        order.trackingNumber( entity.getTrackingNumber() );
        order.notes( entity.getNotes() );
        order.createdAt( entity.getCreatedAt() );
        order.updatedAt( entity.getUpdatedAt() );

        return order.build();
    }

    @Override
    public OrderEntity toEntity(Order domain) {
        if ( domain == null ) {
            return null;
        }

        OrderEntity.OrderEntityBuilder orderEntity = OrderEntity.builder();

        orderEntity.status( statusToString( domain.getStatus() ) );
        orderEntity.id( domain.getId() );
        orderEntity.user( userEntityMapper.toEntity( domain.getUser() ) );
        orderEntity.orderItems( orderItemListToOrderItemEntityList( domain.getOrderItems() ) );
        orderEntity.totalAmount( domain.getTotalAmount() );
        orderEntity.shippingAddress( domain.getShippingAddress() );
        orderEntity.billingAddress( domain.getBillingAddress() );
        orderEntity.paymentMethod( domain.getPaymentMethod() );
        orderEntity.paymentStatus( domain.getPaymentStatus() );
        orderEntity.trackingNumber( domain.getTrackingNumber() );
        orderEntity.notes( domain.getNotes() );
        orderEntity.createdAt( domain.getCreatedAt() );
        orderEntity.updatedAt( domain.getUpdatedAt() );

        return orderEntity.build();
    }

    protected List<OrderItem> orderItemEntityListToOrderItemList(List<OrderItemEntity> list) {
        if ( list == null ) {
            return null;
        }

        List<OrderItem> list1 = new ArrayList<OrderItem>( list.size() );
        for ( OrderItemEntity orderItemEntity : list ) {
            list1.add( orderItemEntityMapper.toDomain( orderItemEntity ) );
        }

        return list1;
    }

    protected List<OrderItemEntity> orderItemListToOrderItemEntityList(List<OrderItem> list) {
        if ( list == null ) {
            return null;
        }

        List<OrderItemEntity> list1 = new ArrayList<OrderItemEntity>( list.size() );
        for ( OrderItem orderItem : list ) {
            list1.add( orderItemEntityMapper.toEntity( orderItem ) );
        }

        return list1;
    }
}
