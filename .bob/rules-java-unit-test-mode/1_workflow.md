# Java Unit Test Writing Workflow

## Overview

This mode helps you write high-quality JUnit 5 unit tests for Spring Boot applications. The workflow ensures tests match the project's existing conventions and provide comprehensive coverage.

## Step-by-Step Workflow

### Step 1: Understand the Request

Parse the user's request to identify:
- What class or method needs testing
- Whether it's a new test class or adding to existing tests
- What scenarios need coverage (happy path, edge cases, error conditions)
- Any specific requirements or constraints

### Step 2: Read Existing Tests

**CRITICAL**: Before writing any test, read existing test files to understand conventions:

1. **Read related test files** under `order-service/src/test/` that test similar components
2. **Identify patterns**:
   - Test class naming (e.g., `OrderServiceTest`, `OrderControllerTest`)
   - Test method naming (e.g., `methodName_scenario_expectedBehavior`)
   - Assertion library usage (AssertJ's `assertThat`)
   - Mocking approach (@Mock, @InjectMocks, @MockBean)
   - Fixture setup patterns (@BeforeEach methods)
   - Import statements and annotations

3. **Match the style**: Your tests must be indistinguishable from existing tests in terms of:
   - Naming conventions
   - Code structure
   - Assertion style
   - Mock setup patterns

### Step 3: Read the Production Code

Read the class under test to understand:
- Method signatures and parameters
- Business logic and behavior
- Dependencies and their usage
- Edge cases and error conditions
- Return types and possible values

### Step 4: Plan Test Coverage

Identify test scenarios:
- **Happy path**: Normal, expected usage
- **Edge cases**: Boundary conditions, empty inputs, null values
- **Error conditions**: Invalid inputs, exceptions, constraint violations
- **State transitions**: For stateful objects
- **Mock interactions**: Verify dependencies are called correctly

### Step 5: Write the Tests

Follow the AAA pattern (Arrange, Act, Assert):

```java
@Test
void methodName_scenario_expectedBehavior() {
    // Arrange: Set up test data and mock behavior
    when(mockDependency.method()).thenReturn(expectedValue);
    
    // Act: Call the method under test
    Result result = serviceUnderTest.method(input);
    
    // Assert: Verify the outcome
    assertThat(result).isNotNull();
    assertThat(result.getValue()).isEqualTo(expectedValue);
}
```

### Step 6: Verify and Validate

Before completing:
- Ensure all imports are correct
- Verify test names follow the convention
- Check that assertions use AssertJ
- Confirm mocks are set up properly
- Ensure tests are independent and don't rely on execution order

## Test Type Guidelines

### Service Layer Tests

Use `@ExtendWith(MockitoExtension.class)`:
- Mock repository dependencies with `@Mock`
- Inject mocks into service with `@InjectMocks`
- Set up test fixtures in `@BeforeEach`
- Verify repository interactions with `verify()`

### Controller Tests

Use `@WebMvcTest(ControllerClass.class)`:
- Mock service layer with `@MockBean`
- Use `MockMvc` for HTTP request simulation
- Test HTTP status codes and response bodies
- Use `jsonPath()` for JSON response assertions

### Repository Tests

Use `@DataJpaTest` for integration tests:
- Test actual database interactions
- Use test database (H2 in-memory)
- Verify query methods work correctly

## Completion Criteria

Tests are complete when:
- All requested scenarios are covered
- Tests follow existing project conventions
- Code compiles without errors
- Tests are readable and maintainable
- Mock interactions are properly verified
- Edge cases and error conditions are tested