package com.example.orders.service;

import com.example.orders.model.Order;
import com.example.orders.repository.OrderRepository;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class OrderService {

    private static final Logger logger = LoggerFactory.getLogger(OrderService.class);

    private final OrderRepository orderRepository;

    public OrderService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    public List<Order> getAllOrders() {
        logger.info("Fetching all orders");
        return orderRepository.findAll();
    }

    public Optional<Order> getOrderById(Long id) {
        logger.info("Fetching order with id: {}", id);
        return orderRepository.findById(id);
    }

    public List<Order> getOrdersByStatus(String status) {
        return orderRepository.findByStatus(status);
    }

    public Order createOrder(Order order) {
        if (order.getStatus() == null) {
            order.setStatus("PENDING");
        }
        logger.info("Creating order for customer: {}", order.getCustomerName());
        return orderRepository.save(order);
    }

    public Order updateOrderStatus(Long id, String status) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found: " + id));

        validateStatusTransition(order.getStatus(), status);
        order.setStatus(status);
        logger.info("Updated order {} status to {}", id, status);
        return orderRepository.save(order);
    }

    public void deleteOrder(Long id) {
        logger.info("Deleting order with id: {}", id);
        orderRepository.deleteById(id);
    }

    private void validateStatusTransition(String currentStatus, String newStatus) {
        // Valid transitions: PENDING -> CONFIRMED -> SHIPPED -> DELIVERED
        //                    Any status -> CANCELLED
        if ("CANCELLED".equals(newStatus)) {
            return;
        }
        switch (currentStatus) {
            case "PENDING":
                if (!"CONFIRMED".equals(newStatus)) {
                    throw new IllegalStateException(
                            "Cannot transition from PENDING to " + newStatus);
                }
                break;
            case "CONFIRMED":
                if (!"SHIPPED".equals(newStatus)) {
                    throw new IllegalStateException(
                            "Cannot transition from CONFIRMED to " + newStatus);
                }
                break;
            case "SHIPPED":
                if (!"DELIVERED".equals(newStatus)) {
                    throw new IllegalStateException(
                            "Cannot transition from SHIPPED to " + newStatus);
                }
                break;
            case "DELIVERED":
            case "CANCELLED":
                throw new IllegalStateException(
                        "Cannot transition from terminal status: " + currentStatus);
            default:
                throw new IllegalStateException("Unknown status: " + currentStatus);
        }
    }
}
