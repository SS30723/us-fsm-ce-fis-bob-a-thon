# Tool Usage Guidelines for Java Unit Testing

## Tool Priority and Usage

### 1. Read Existing Tests First (CRITICAL)

**Always start by reading existing test files** to understand the project's conventions:

```
<read_file>
<args>
  <file>
    <path>order-service/src/test/java/com/example/orders/service/OrderServiceTest.java</path>
  </file>
  <file>
    <path>order-service/src/test/java/com/example/orders/controller/OrderControllerTest.java</path>
  </file>
</args>
</read_file>
```

**Why**: This ensures your tests match the existing style, naming conventions, and patterns.

### 2. Read Production Code

Read the class you're testing to understand its behavior:

```
<read_file>
<args>
  <file>
    <path>order-service/src/main/java/com/example/orders/service/OrderService.java</path>
  </file>
</args>
</read_file>
```

### 3. List Test Directory Structure

If you need to understand the test organization:

```
<list_files>
<path>order-service/src/test/java</path>
<recursive>true</recursive>
</list_files>
```

### 4. Search for Similar Tests

Find tests for similar functionality:

```
<search_files>
<path>order-service/src/test</path>
<regex>@Test.*void.*update.*Status</regex>
<file_pattern>*.java</file_pattern>
</search_files>
```

## Writing Tests

### For New Test Classes

Use `write_to_file` to create a complete new test class:

```
<write_to_file>
<path>order-service/src/test/java/com/example/orders/service/NewServiceTest.java</path>
<content>
package com.example.orders.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NewServiceTest {
    
    @Mock
    private DependencyRepository repository;
    
    @InjectMocks
    private NewService service;
    
    private TestEntity testEntity;
    
    @BeforeEach
    void setUp() {
        testEntity = new TestEntity();
        testEntity.setId(1L);
    }
    
    @Test
    void methodName_scenario_expectedBehavior() {
        // Arrange
        when(repository.findById(1L)).thenReturn(Optional.of(testEntity));
        
        // Act
        TestEntity result = service.methodName(1L);
        
        // Assert
        assertThat(result).isNotNull();
    }
}