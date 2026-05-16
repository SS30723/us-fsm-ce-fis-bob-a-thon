# Complete Test Examples

## Service Layer Test Example

Based on `OrderServiceTest.java`, here's a complete example:

```java
package com.example.orders.service;

import com.example.orders.model.Order;
import com.example.orders.repository.OrderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderService orderService;

    private Order testOrder;

    @BeforeEach
    void setUp() {
        testOrder = new Order();
        testOrder.setId(1L);
        testOrder.setCustomerName("John Doe");
        testOrder.setProduct("Widget");
        testOrder.setAmount(new BigDecimal("29.99"));
        testOrder.setStatus("PENDING");
    }

    @Test
    void getAllOrders_returnsAllOrders() {
        when(orderRepository.findAll()).thenReturn(Arrays.asList(testOrder));
        
        List<Order> orders = orderService.getAllOrders();
        
        assertThat(orders).hasSize(1);
        assertThat(orders.get(0).getCustomerName()).isEqualTo("John Doe");
    }

    @Test
    void getOrderById_existingId_returnsOrder() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(testOrder));
        
        Optional<Order> result = orderService.getOrderById(1L);
        
        assertThat(result).isPresent();
        assertThat(result.get().getProduct()).isEqualTo("Widget");
    }

    @Test
    void getOrderById_nonExistingId_returnsEmpty() {
        when(orderRepository.findById(99L)).thenReturn(Optional.empty());
        
        Optional<Order> result = orderService.getOrderById(99L);
        
        assertThat(result).isEmpty();
    }

    @Test
    void createOrder_setsDefaultStatus() {
        Order newOrder = new Order();
        newOrder.setCustomerName("Jane");
        newOrder.setProduct("Gadget");
        newOrder.setAmount(new BigDecimal("49.99"));

        when(orderRepository.save(any(Order.class))).thenReturn(newOrder);

        Order created = orderService.createOrder(newOrder);
        
        assertThat(created.getStatus()).isEqualTo("PENDING");
    }

    @Test
    void updateOrderStatus_validTransition_succeeds() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(testOrder));
        when(orderRepository.save(any(Order.class))).thenReturn(testOrder);

        Order updated = orderService.updateOrderStatus(1L, "CONFIRMED");
        
        assertThat(updated.getStatus()).isEqualTo("CONFIRMED");
    }

    @Test
    void updateOrderStatus_invalidTransition_throwsException() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(testOrder));

        assertThatThrownBy(() -> orderService.updateOrderStatus(1L, "DELIVERED"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot transition from PENDING to DELIVERED");
    }

    @Test
    void deleteOrder_callsRepository() {
        orderService.deleteOrder(1L);
        
        verify(orderRepository).deleteById(1L);
    }
}
```

## Controller Layer Test Example

Based on `OrderControllerTest.java`, here's a complete example:

```java
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
}
```

## Testing Different Scenarios

### Testing Null Handling

```java
@Test
void method_nullInput_throwsException() {
    assertThatThrownBy(() -> service.process(null))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Input cannot be null");
}

@Test
void method_nullField_handlesGracefully() {
    Entity entity = new Entity();
    entity.setOptionalField(null);
    
    when(repository.save(any(Entity.class))).thenReturn(entity);
    
    Entity result = service.save(entity);
    
    assertThat(result.getOptionalField()).isNull();
}
```

### Testing Empty Collections

```java
@Test
void getAll_noItems_returnsEmptyList() {
    when(repository.findAll()).thenReturn(Arrays.asList());
    
    List<Item> results = service.getAll();
    
    assertThat(results).isEmpty();
}

@Test
void processItems_emptyList_returnsZero() {
    int count = service.processItems(Arrays.asList());
    
    assertThat(count).isZero();
}
```

### Testing Boundary Conditions

```java
@Test
void calculateDiscount_minimumAmount_appliesNoDiscount() {
    BigDecimal amount = new BigDecimal("10.00");
    
    BigDecimal discount = service.calculateDiscount(amount);
    
    assertThat(discount).isEqualByComparingTo(BigDecimal.ZERO);
}

@Test
void calculateDiscount_thresholdAmount_appliesDiscount() {
    BigDecimal amount = new BigDecimal("100.00");
    
    BigDecimal discount = service.calculateDiscount(amount);
    
    assertThat(discount).isGreaterThan(BigDecimal.ZERO);
}
```

### Testing State Transitions

```java
@Test
void transition_validSequence_succeeds() {
    entity.setStatus("PENDING");
    when(repository.findById(1L)).thenReturn(Optional.of(entity));
    when(repository.save(any(Entity.class))).thenReturn(entity);
    
    Entity result = service.transition(1L, "CONFIRMED");
    
    assertThat(result.getStatus()).isEqualTo("CONFIRMED");
}

@Test
void transition_invalidSequence_throwsException() {
    entity.setStatus("COMPLETED");
    when(repository.findById(1L)).thenReturn(Optional.of(entity));
    
    assertThatThrownBy(() -> service.transition(1L, "PENDING"))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Cannot transition from COMPLETED to PENDING");
}
```

### Testing Multiple Mock Interactions

```java
@Test
void complexOperation_callsMultipleDependencies() {
    when(repository.findById(1L)).thenReturn(Optional.of(entity));
    when(validator.validate(entity)).thenReturn(true);
    when(processor.process(entity)).thenReturn(processedEntity);
    when(repository.save(any(Entity.class))).thenReturn(processedEntity);
    
    Entity result = service.complexOperation(1L);
    
    assertThat(result).isNotNull();
    verify(repository).findById(1L);
    verify(validator).validate(entity);
    verify(processor).process(entity);
    verify(repository).save(processedEntity);
}
```

## Common Test Patterns Summary

1. **Happy Path**: Test normal, expected behavior
2. **Not Found**: Test when entities don't exist (return Optional.empty())
3. **Validation Failure**: Test invalid inputs throw appropriate exceptions
4. **State Transitions**: Test valid and invalid state changes
5. **Boundary Conditions**: Test edge cases and limits
6. **Null Handling**: Test null inputs and null fields
7. **Empty Collections**: Test behavior with empty lists/sets
8. **Mock Verification**: Verify important interactions with dependencies