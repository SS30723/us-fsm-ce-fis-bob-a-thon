package com.example.orders.controller;

import com.example.orders.model.Order;
import com.example.orders.service.OrderService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void getAllOrders_returnsOrderList() throws Exception {
        Order order = new Order();
        order.setId(1L);
        order.setCustomerName("John");
        order.setProduct("Widget");
        order.setAmount(new BigDecimal("29.99"));
        order.setStatus("PENDING");

        when(orderService.getAllOrders()).thenReturn(Arrays.asList(order));

        mockMvc.perform(get("/api/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].customerName").value("John"));
    }

    @Test
    void getOrderById_existingId_returnsOrder() throws Exception {
        Order order = new Order();
        order.setId(1L);
        order.setCustomerName("Jane");
        order.setProduct("Gadget");
        order.setAmount(new BigDecimal("49.99"));
        order.setStatus("PENDING");

        when(orderService.getOrderById(1L)).thenReturn(Optional.of(order));

        mockMvc.perform(get("/api/orders/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.customerName").value("Jane"));
    }

    @Test
    void getOrderById_nonExistingId_returns404() throws Exception {
        when(orderService.getOrderById(99L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/orders/99"))
                .andExpect(status().isNotFound());
    }

    @Test
    void createOrder_validOrder_returns201() throws Exception {
        Order order = new Order();
        order.setCustomerName("Bob");
        order.setProduct("Thing");
        order.setAmount(new BigDecimal("19.99"));
        order.setStatus("PENDING");

        when(orderService.createOrder(any(Order.class))).thenReturn(order);

        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(order)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.customerName").value("Bob"));
    }

    @Test
    void createOrder_missingFields_returns400() throws Exception {
        Order order = new Order();
        // Missing required fields

        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(order)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void health_returnsUp() throws Exception {
        mockMvc.perform(get("/api/orders/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}
