# APP_SPEC — Spring Boot Order Service

Every file in the `order-service/` directory, with complete contents.

---

## `order-service/pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>order-service</artifactId>
    <version>1.0.0</version>
    <name>order-service</name>
    <description>Simple order service for SRE deployment demo</description>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <!-- Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- JPA + PostgreSQL -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- Validation -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <!-- Health checks -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <!-- Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
            <!-- Checkstyle for linting -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-checkstyle-plugin</artifactId>
                <version>3.3.1</version>
                <dependencies>
                    <dependency>
                        <groupId>com.puppycrawl.tools</groupId>
                        <artifactId>checkstyle</artifactId>
                        <version>10.12.7</version>
                    </dependency>
                </dependencies>
            </plugin>
        </plugins>
    </build>
</project>
```

---

## `order-service/src/main/java/com/example/orders/OrderApplication.java`

```java
package com.example.orders;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class OrderApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrderApplication.class, args);
    }
}
```

---

## `order-service/src/main/java/com/example/orders/model/Order.java`

```java
package com.example.orders.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Customer name is required")
    @Column(name = "customer_name")
    private String customerName;

    @NotBlank(message = "Product is required")
    private String product;

    @NotNull(message = "Amount is required")
    @Positive(message = "Amount must be positive")
    private BigDecimal amount;

    @NotBlank(message = "Status is required")
    private String status;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public Order() {
        this.createdAt = LocalDateTime.now();
        this.status = "PENDING";
    }

    // Getters and setters

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getProduct() { return product; }
    public void setProduct(String product) { this.product = product; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
```

---

## `order-service/src/main/java/com/example/orders/repository/OrderRepository.java`

```java
package com.example.orders.repository;

import com.example.orders.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByStatus(String status);
    List<Order> findByCustomerName(String customerName);
}
```

---

## `order-service/src/main/java/com/example/orders/service/OrderService.java`

```java
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
```

---

## `order-service/src/main/java/com/example/orders/controller/OrderController.java`

```java
package com.example.orders.controller;

import com.example.orders.model.Order;
import com.example.orders.service.OrderService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public List<Order> getAllOrders() {
        return orderService.getAllOrders();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Order> getOrderById(@PathVariable Long id) {
        return orderService.getOrderById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/status/{status}")
    public List<Order> getOrdersByStatus(@PathVariable String status) {
        return orderService.getOrdersByStatus(status);
    }

    @PostMapping
    public ResponseEntity<Order> createOrder(@Valid @RequestBody Order order) {
        Order created = orderService.createOrder(order);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateOrderStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        try {
            String newStatus = body.get("status");
            Order updated = orderService.updateOrderStatus(id, newStatus);
            return ResponseEntity.ok(updated);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOrder(@PathVariable Long id) {
        orderService.deleteOrder(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "UP", "service", "order-service"));
    }
}
```

---

## `order-service/src/main/resources/application.properties`

```properties
spring.application.name=order-service
server.port=8080

# PostgreSQL
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:orders}
spring.datasource.username=${DB_USER:orderuser}
spring.datasource.password=${DB_PASS:orderpass}
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# Actuator health endpoints
management.endpoints.web.exposure.include=health
management.endpoint.health.probes.enabled=true
management.health.livenessstate.enabled=true
management.health.readinessstate.enabled=true
```

---

## `order-service/src/test/resources/application-test.properties`

```properties
spring.datasource.url=jdbc:h2:mem:testdb;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
```

---

## `order-service/src/test/java/com/example/orders/service/OrderServiceTest.java`

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
    void updateOrderStatus_cancelFromAnyStatus_succeeds() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(testOrder));
        when(orderRepository.save(any(Order.class))).thenReturn(testOrder);

        Order updated = orderService.updateOrderStatus(1L, "CANCELLED");
        assertThat(updated.getStatus()).isEqualTo("CANCELLED");
    }

    @Test
    void updateOrderStatus_fromTerminalStatus_throwsException() {
        testOrder.setStatus("DELIVERED");
        when(orderRepository.findById(1L)).thenReturn(Optional.of(testOrder));

        assertThatThrownBy(() -> orderService.updateOrderStatus(1L, "SHIPPED"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot transition from terminal status");
    }

    @Test
    void deleteOrder_callsRepository() {
        orderService.deleteOrder(1L);
        verify(orderRepository).deleteById(1L);
    }
}
```

---

## `order-service/src/test/java/com/example/orders/controller/OrderControllerTest.java`

```java
package com.example.orders.controller;

import com.example.orders.model.Order;
import com.example.orders.service.OrderService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.bean.MockBean;
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
```

---

## `order-service/src/main/resources/application-staging.properties`

Staging profile — used when `SPRING_PROFILES_ACTIVE=staging`. Overrides the defaults in `application.properties` for a staging environment.

```properties
# Staging database (external managed PostgreSQL)
spring.datasource.url=jdbc:postgresql://${DB_HOST:staging-db.internal}:${DB_PORT:5432}/${DB_NAME:orders_staging}
spring.datasource.username=${DB_USER:orderuser}
spring.datasource.password=${DB_PASS:orderpass}

# Connection pooling — moderate for staging
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=3
spring.datasource.hikari.connection-timeout=30000

# JPA — validate schema, don't auto-modify
spring.jpa.hibernate.ddl-auto=validate

# Logging — more verbose than prod for debugging
logging.level.root=INFO
logging.level.com.example.orders=DEBUG

# Actuator — expose more endpoints for debugging
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=when-authorized
```

---

## `order-service/src/main/resources/application-prod.properties`

Production profile — used when `SPRING_PROFILES_ACTIVE=prod`. Locked-down settings for a PCI-regulated environment.

```properties
# Production database (external managed PostgreSQL)
spring.datasource.url=jdbc:postgresql://${DB_HOST}:${DB_PORT:5432}/${DB_NAME}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASS}

# Connection pooling — sized for production traffic
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.max-lifetime=1800000
spring.datasource.hikari.leak-detection-threshold=60000

# JPA — NEVER auto-modify schema in production
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=false

# Logging — minimal, structured for log aggregation
logging.level.root=WARN
logging.level.com.example.orders=INFO
logging.level.org.springframework.web=WARN
logging.pattern.console=%d{ISO8601} %-5level [%thread] %logger{36} - %msg%n

# Actuator — restrict endpoints in production (PCI requirement)
management.endpoints.web.exposure.include=health
management.endpoint.health.show-details=never

# Server — security headers
server.error.include-stacktrace=never
server.error.include-message=never
```

---

## `order-service/Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY target/order-service-1.0.0.jar app.jar

EXPOSE 8080

ENV DB_HOST=order-db \
    DB_PORT=5432 \
    DB_NAME=orders \
    DB_USER=orderuser \
    DB_PASS=orderpass

ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## Notes for Implementation

- The application has **9 unit tests** across 2 test files — enough to demonstrate test passes and failures
- Status transitions (PENDING → CONFIRMED → SHIPPED → DELIVERED) provide a natural place to introduce bugs for the `lab/test-failure` branch
- The `OrderService.validateStatusTransition()` method is the primary target for demo breakage — removing the validation or altering it creates realistic test failures
- `application-test.properties` uses H2 in PostgreSQL compatibility mode, same pattern as the existing dental claims project
- The `/api/orders/health` endpoint is used by the smoke test script, separate from the Actuator endpoints which are used by Kubernetes probes
- **Three Spring profiles** exist: default (dev), staging, and prod. The active profile is set via the `SPRING_PROFILES_ACTIVE` environment variable in the deployment YAML or ConfigMap. This is the foundation for the Bob properties file generation demo — Bob can analyze the code and generate new profiles for additional environments (e.g., `application-onprem-prod.properties` or `application-cloud-staging.properties`)
- The production properties file intentionally follows PCI best practices: `show-sql=false`, `include-stacktrace=never`, `health.show-details=never`, `ddl-auto=validate`. Bob should explain WHY each setting matters when generating or reviewing properties files
