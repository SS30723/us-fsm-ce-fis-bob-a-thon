# Testing Conventions and Best Practices

## Project-Specific Conventions

Based on the existing tests in `order-service/src/test/`, follow these conventions:

### Test Class Structure

```java
@ExtendWith(MockitoExtension.class)  // For service tests
class ServiceNameTest {
    
    @Mock
    private DependencyRepository repository;
    
    @InjectMocks
    private ServiceName service;
    
    private TestEntity testEntity;
    
    @BeforeEach
    void setUp() {
        // Initialize test fixtures
        testEntity = new TestEntity();
        testEntity.setId(1L);
        testEntity.setName("Test");
    }
    
    @Test
    void methodName_scenario_expectedBehavior() {
        // Test implementation
    }
}
```

### Naming Conventions

#### Test Class Names
- Pattern: `{ClassName}Test`
- Examples: `OrderServiceTest`, `OrderControllerTest`
- Location: Mirror production package structure under `src/test/java/`

#### Test Method Names
- Pattern: `methodName_scenario_expectedBehavior`
- Use underscores to separate parts
- Be descriptive but concise
- Examples:
  - `getAllOrders_returnsAllOrders`
  - `getOrderById_existingId_returnsOrder`
  - `getOrderById_nonExistingId_returnsEmpty`
  - `updateOrderStatus_invalidTransition_throwsException`

#### Test Fixture Variables
- Use descriptive names: `testOrder`, `testCustomer`
- Initialize in `@BeforeEach` when used by multiple tests
- Keep fixtures simple and focused

### Assertion Style

**ALWAYS use AssertJ** (`assertThat`), never JUnit assertions:

```java
// ✅ CORRECT - AssertJ
assertThat(result).isNotNull();
assertThat(result.getName()).isEqualTo("Expected");
assertThat(list).hasSize(3);
assertThat(optional).isPresent();
assertThat(optional).isEmpty();

// ❌ WRONG - JUnit assertions
assertEquals("Expected", result.getName());
assertTrue(result != null);
```

### Exception Testing

Use AssertJ's `assertThatThrownBy`:

```java
@Test
void methodName_invalidInput_throwsException() {
    assertThatThrownBy(() -> service.method(invalidInput))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("expected error message");
}
```

### Mock Setup

#### Service Layer Tests

```java
@Mock
private OrderRepository orderRepository;

@InjectMocks
private OrderService orderService;

@Test
void testMethod() {
    // Setup mock behavior
    when(orderRepository.findById(1L)).thenReturn(Optional.of(testOrder));
    when(orderRepository.save(any(Order.class))).thenReturn(testOrder);
    
    // Execute test
    Order result = orderService.getOrderById(1L);
    
    // Verify interactions
    verify(orderRepository).findById(1L);
}
```

#### Controller Layer Tests

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private OrderService orderService;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @Test
    void testEndpoint() throws Exception {
        when(orderService.getAll()).thenReturn(Arrays.asList(order));
        
        mockMvc.perform(get("/api/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("Expected"));
    }
}
```

## General Best Practices

### Test Independence
- Each test should be independent
- Don't rely on test execution order
- Clean up state in `@AfterEach` if needed
- Use `@BeforeEach` for common setup

### Test Focus
- One logical assertion per test
- Test one scenario per test method
- Keep tests simple and readable
- Avoid complex logic in tests

### Mock Usage
- Mock external dependencies (repositories, services)
- Don't mock the class under test
- Use `any()` matchers when exact values don't matter
- Use specific matchers when values are important

### Fixture Management
- Create fixtures in `@BeforeEach` for reusability
- Keep fixtures minimal - only set required fields
- Use builder pattern for complex objects (if available)
- Don't share mutable fixtures between tests

### Coverage Goals
- Test happy paths (normal operation)
- Test edge cases (boundaries, empty, null)
- Test error conditions (exceptions, validation failures)
- Test state transitions (for stateful objects)
- Verify mock interactions when important

## Common Patterns

### Testing Optional Returns

```java
@Test
void method_found_returnsPresent() {
    when(repository.findById(1L)).thenReturn(Optional.of(entity));
    
    Optional<Entity> result = service.findById(1L);
    
    assertThat(result).isPresent();
    assertThat(result.get().getName()).isEqualTo("Expected");
}

@Test
void method_notFound_returnsEmpty() {
    when(repository.findById(99L)).thenReturn(Optional.empty());
    
    Optional<Entity> result = service.findById(99L);
    
    assertThat(result).isEmpty();
}
```

### Testing Collections

```java
@Test
void method_returnsMultipleItems() {
    when(repository.findAll()).thenReturn(Arrays.asList(item1, item2));
    
    List<Item> results = service.getAll();
    
    assertThat(results).hasSize(2);
    assertThat(results).extracting(Item::getName)
            .containsExactly("Name1", "Name2");
}
```

### Testing State Changes

```java
@Test
void method_updatesState() {
    when(repository.findById(1L)).thenReturn(Optional.of(entity));
    when(repository.save(any(Entity.class))).thenReturn(entity);
    
    Entity updated = service.updateStatus(1L, "NEW_STATUS");
    
    assertThat(updated.getStatus()).isEqualTo("NEW_STATUS");
    verify(repository).save(entity);
}
```

### Testing Validation

```java
@Test
void method_invalidInput_throwsException() {
    assertThatThrownBy(() -> service.create(null))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("cannot be null");
}
```

## Import Statements

Standard imports for tests:

```java
// JUnit 5
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

// Mockito
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

// AssertJ
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

// Spring Test (for controllers)
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;