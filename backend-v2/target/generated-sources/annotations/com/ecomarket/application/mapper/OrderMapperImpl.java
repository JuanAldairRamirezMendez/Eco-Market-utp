package com.ecomarket.application.mapper;

import com.ecomarket.application.dto.response.OrderItemResponse;
import com.ecomarket.application.dto.response.OrderResponse;
import com.ecomarket.domain.model.Order;
import com.ecomarket.domain.model.OrderItem;
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
public class OrderMapperImpl implements OrderMapper {

    @Autowired
    private OrderItemMapper orderItemMapper;

    @Override
    public OrderResponse toResponse(Order order) {
        if ( order == null ) {
            return null;
        }

        OrderResponse.OrderResponseBuilder orderResponse = OrderResponse.builder();

        orderResponse.id( order.getId() );
        orderResponse.orderItems( orderItemListToOrderItemResponseList( order.getOrderItems() ) );
        orderResponse.totalAmount( order.getTotalAmount() );
        orderResponse.shippingAddress( order.getShippingAddress() );
        orderResponse.billingAddress( order.getBillingAddress() );
        orderResponse.paymentMethod( order.getPaymentMethod() );
        orderResponse.paymentStatus( order.getPaymentStatus() );
        orderResponse.trackingNumber( order.getTrackingNumber() );
        orderResponse.notes( order.getNotes() );

        orderResponse.userId( getUserId(order) );
        orderResponse.username( getUsername(order) );
        orderResponse.status( getStatusString(order) );

        return orderResponse.build();
    }

    @Override
    public List<OrderResponse> toResponseList(List<Order> orders) {
        if ( orders == null ) {
            return null;
        }

        List<OrderResponse> list = new ArrayList<OrderResponse>( orders.size() );
        for ( Order order : orders ) {
            list.add( toResponse( order ) );
        }

        return list;
    }

    protected List<OrderItemResponse> orderItemListToOrderItemResponseList(List<OrderItem> list) {
        if ( list == null ) {
            return null;
        }

        List<OrderItemResponse> list1 = new ArrayList<OrderItemResponse>( list.size() );
        for ( OrderItem orderItem : list ) {
            list1.add( orderItemMapper.toResponse( orderItem ) );
        }

        return list1;
    }
}
