# Troubleshooting Common Test Issues

## Compilation Errors

### Missing Imports

**Problem**: Test doesn't compile due to missing imports.

**Solution**: Add the required imports at the top of the file:

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
```

### Wrong Assertion Library

**Problem**: Using JUnit assertions instead of AssertJ.

**Wrong**:
```java
assertEquals(expected, actual);
assertTrue(condition);
```

**Correct**:
```java
assertThat(actual).isEqualTo(expected);
assertThat(condition).isTrue();
```

## Mock Configuration Issues

### NullPointerException in Tests

**Problem**: Getting NPE when calling mocked methods.

**Cause**: Mock behavior not configured.

**Solution**: Set up mock return values:

```java
@Test
void testMethod() {
    // Configure mock BEFORE calling the method
    when(mockRepository.findById(1L)).thenReturn(Optional.of(entity));
    
    // Now call the method
    Entity result = service.getById(1L);
    
    assertThat(result).isNotNull();
}
```

### UnnecessaryStubbingException

**Problem**: Mockito complains about unused stubs.

**Cause**: Configured mock behavior that wasn't used in the test.

**Solution**: Only configure mocks that will actually be called:

```java
@Test
void testMethod() {
    // Only stub what you need
    when(mockRepository.findById(1L)).thenReturn(Optional.of(entity));
    
    // Make sure this actually calls findById
    Entity result = service.getById(1L);
}
```

### ArgumentMatchers Issues

**Problem**: Mock not matching when using matchers.

**Solution**: Use matchers consistently:

```java
// ✅ CORRECT - all matchers
when(service.method(any(String.class), any(Integer.class)))
    .thenReturn(result);

// ✅ CORRECT - no matchers
when(service.method("specific", 123))
    .thenReturn(result);

// ❌ WRONG - mixing matchers and literals
when(service.method(any(String.class), 123))
    .thenReturn(result);
```

## Test Failures

### Assertion Failures

**Problem**: Test fails with assertion error.

**Debugging Steps**:
1. Check the actual vs expected values in the error message
2. Verify mock setup returns correct values
3. Add debug logging if needed
4. Check if the production code logic is correct

**Example**:
```java
@Test
void testMethod() {
    when(repository.findById(1L)).thenReturn(Optional.of(testEntity));
    
    Entity result = service.getById(1L);
    
    // If this fails, check:
    // 1. Does repository.findById actually return testEntity?
    // 2. Does service.getById modify the entity?
    // 3. Is getName() returning what you expect?
    assertThat(result.getName()).isEqualTo("Expected Name");
}
```

### Optional Assertion Failures

**Problem**: Optional assertions fail unexpectedly.

**Common Issues**:
```java
// ❌ WRONG - comparing Optional to value
assertThat(optionalResult).isEqualTo(expectedValue);

// ✅ CORRECT - check presence first
assertThat(optionalResult).isPresent();
assertThat(optionalResult.get()).isEqualTo(expectedValue);

// ✅ ALSO CORRECT - use hasValue
assertThat(optionalResult).hasValue(expectedValue);
```

### Exception Not Thrown

**Problem**: Expected exception not thrown in test.

**Debugging**:
```java
@Test
void method_invalidInput_throwsException() {
    // Make sure the condition that triggers the exception is met
    when(repository.findById(99L)).thenReturn(Optional.empty());
    
    // Verify the exception is actually thrown
    assertThatThrownBy(() -> service.getById(99L))
            .isInstanceOf(EntityNotFoundException.class)
            .hasMessageContaining("not found");
}
```

## Spring Test Issues

### Controller Test 404 Errors

**Problem**: MockMvc returns 404 for valid endpoints.

**Solution**: Check the request mapping:

```java
@Test
void testEndpoint() throws Exception {
    // Make sure the path matches the controller mapping
    mockMvc.perform(get("/api/orders"))  // Check controller @RequestMapping
            .andExpect(status().isOk());
}
```

### JSON Path Failures

**Problem**: jsonPath assertions fail.

**Solution**: Verify the JSON structure:

```java
@Test
void testJsonResponse() throws Exception {
    mockMvc.perform(get("/api/orders/1"))
            .andExpect(status().isOk())
            // For single object: $.fieldName
            .andExpect(jsonPath("$.customerName").value("John"))
            // For array: $[index].fieldName
            .andExpect(jsonPath("$[0].customerName").value("John"))
            // Check array size
            .andExpect(jsonPath("$").isArray())
            .andExpect(jsonPath("$", hasSize(1)));
}
```

### MockBean Not Injected

**Problem**: Service is null in controller test.

**Solution**: Use @MockBean, not @Mock:

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    // ✅ CORRECT - for Spring beans
    @MockBean
    private OrderService orderService;
    
    // ❌ WRONG - @Mock doesn't work with Spring context
    // @Mock
    // private OrderService orderService;
}
```

## Test Organization Issues

### Test Not Running

**Problem**: Test method not executed.

**Causes and Solutions**:

1. **Missing @Test annotation**:
```java
// ❌ WRONG
void testMethod() { }

// ✅ CORRECT
@Test
void testMethod() { }
```

2. **Wrong JUnit version**:
```java
// ❌ WRONG - JUnit 4
import org.junit.Test;

// ✅ CORRECT - JUnit 5
import org.junit.jupiter.api.Test;
```

3. **Test class not public** (not required in JUnit 5, but check if using older conventions)

### Setup Not Running

**Problem**: @BeforeEach method not executing.

**Solution**: Check annotation and method signature:

```java
// ✅ CORRECT
@BeforeEach
void setUp() {
    testEntity = new TestEntity();
}

// ❌ WRONG - typo in annotation
@BeforeEach
void setup() {  // Note: method name doesn't matter, annotation does
    testEntity = new TestEntity();
}
```

## Best Practices for Debugging

### 1. Run Tests in Isolation

Test one method at a time to isolate issues:

```bash
mvn test -Dtest=OrderServiceTest#specificTestMethod
```

### 2. Add Temporary Debug Output

```java
@Test
void debugTest() {
    when(repository.findById(1L)).thenReturn(Optional.of(testEntity));
    
    Entity result = service.getById(1L);
    
    // Temporary debug output
    System.out.println("Result: " + result);
    System.out.println("Name: " + result.getName());
    
    assertThat(result.getName()).isEqualTo("Expected");
}
```

### 3. Verify Mock Interactions

Check if mocks are being called as expected:

```java
@Test
void verifyMockCalls() {
    service.method(1L);
    
    // Verify the mock was called
    verify(repository).findById(1L);
    
    // Verify it was called exactly once
    verify(repository, times(1)).findById(1L);
    
    // Verify it was never called
    verify(repository, never()).deleteById(any());
}
```

### 4. Check Test Execution Order

If tests pass individually but fail together, they may have shared state:

```java
// ✅ GOOD - each test is independent
@BeforeEach
void setUp() {
    testEntity = new TestEntity();  // Fresh instance each time
}

// ❌ BAD - shared mutable state
private static TestEntity testEntity = new TestEntity();
```

## Common Error Messages

### "Wanted but not invoked"

**Meaning**: Expected a mock method to be called, but it wasn't.

**Solution**: Check that your code actually calls the mocked method.

### "Argument(s) are different"

**Meaning**: Mock was called with different arguments than configured.

**Solution**: Use `any()` matchers or verify the exact arguments being passed.

### "Cannot mock final class"

**Meaning**: Trying to mock a final class or method.

**Solution**: Either make the class/method non-final, or use Mockito's inline mock maker.

### "No tests found"

**Meaning**: Maven/JUnit can't find any test methods.

**Solution**: Check @Test annotations and ensure using JUnit 5 imports.