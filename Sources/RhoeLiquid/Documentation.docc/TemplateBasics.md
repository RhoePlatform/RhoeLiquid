# Template Basics

Master the fundamentals of Liquid template syntax and features in RhoeLiquid.

## Overview

Liquid is a template language created by Shopify that allows you to create dynamic content by combining static text with dynamic data. RhoeLiquid provides a complete, high-performance implementation of Liquid for Swift.

## Template Syntax

### Variables

Variables are enclosed in double curly braces `{{ }}` and are replaced with their values:

```liquid
Hello {{ name }}!
Welcome to {{ site.title }}.
```

### Tags

Tags are enclosed in curly braces with percent signs `{% %}` and perform logic operations:

```liquid
{% if user.premium %}
  Premium content here
{% endif %}
```

### Filters

Filters modify variables using the pipe operator `|`:

```liquid
{{ name | upcase }}
{{ price | round: 2 }}
```

## Variables and Data Access

### Basic Variables

```swift
let context = ["name": "Alice", "age": 25]
let template = "Hello {{ name }}, you are {{ age }} years old."
// Output: "Hello Alice, you are 25 years old."
```

### Object Properties

Access object properties using dot notation:

```swift
let context = [
    "user": [
        "name": "Bob",
        "email": "bob@example.com",
        "profile": [
            "bio": "Software developer"
        ]
    ]
]

let template = """
Name: {{ user.name }}
Email: {{ user.email }}
Bio: {{ user.profile.bio }}
"""
```

### Array Elements

Access array elements by index:

```swift
let context = [
    "items": ["apple", "banana", "cherry"],
    "numbers": [1, 2, 3, 4, 5]
]

let template = """
First item: {{ items[0] }}
Third number: {{ numbers[2] }}
Last item: {{ items[-1] }}
"""
```

### Dynamic Access

Use variables as property keys:

```swift
let template = """
{% assign key = "name" %}
Value: {{ user[key] }}
"""
```

## Control Flow

### If Statements

```liquid
{% if user.age >= 18 %}
  You are an adult.
{% elsif user.age >= 13 %}
  You are a teenager.
{% else %}
  You are a child.
{% endif %}
```

### Unless Statements

```liquid
{% unless user.banned %}
  Welcome back!
{% endunless %}
```

### Case Statements

```liquid
{% case user.role %}
  {% when "admin" %}
    Admin panel access
  {% when "moderator" %}
    Moderation tools
  {% when "user" %}
    User dashboard
  {% else %}
    Please log in
{% endcase %}
```

## Loops

### For Loops

Iterate over arrays:

```liquid
{% for item in items %}
  {{ forloop.index }}: {{ item }}
{% endfor %}
```

### For Loop Variables

Special variables available in loops:

- `forloop.index`: Current iteration (1-based)
- `forloop.index0`: Current iteration (0-based)
- `forloop.first`: True if first iteration
- `forloop.last`: True if last iteration
- `forloop.length`: Total number of iterations
- `forloop.rindex`: Reverse index (from end)
- `forloop.rindex0`: Reverse index (0-based from end)

```liquid
{% for product in products %}
  <div class="product{% if forloop.first %} first{% endif %}{% if forloop.last %} last{% endif %}">
    {{ forloop.index }}. {{ product.name }}
  </div>
{% endfor %}
```

### Loop Parameters

Control loop behavior with parameters:

```liquid
{% for item in items limit: 5 %}
  {{ item }}
{% endfor %}

{% for item in items offset: 2 %}
  {{ item }}
{% endfor %}

{% for item in items limit: 3 offset: 2 %}
  {{ item }}
{% endfor %}

{% for item in items reversed %}
  {{ item }}
{% endfor %}
```

### Table Rows

Create HTML tables with `tablerow`:

```liquid
<table>
  {% tablerow product in products cols: 3 %}
    <strong>{{ product.name }}</strong>
    <br>
    ${{ product.price }}
  {% endtablerow %}
</table>
```

### Ranges

Loop over number ranges:

```liquid
{% for i in (1..5) %}
  Item {{ i }}
{% endfor %}

{% for i in (0..items.size) %}
  Processing {{ i }}
{% endfor %}
```

## Filters

### String Filters

```liquid
{{ "hello world" | upcase }}          <!-- HELLO WORLD -->
{{ "HELLO WORLD" | downcase }}        <!-- hello world -->
{{ "hello world" | capitalize }}      <!-- Hello world -->
{{ "  hello  " | strip }}             <!-- hello -->
{{ "hello" | append: " world" }}      <!-- hello world -->
{{ "world" | prepend: "hello " }}     <!-- hello world -->
{{ "hello-world" | split: "-" }}      <!-- ["hello", "world"] -->
```

### Array Filters

```liquid
{{ items | size }}                     <!-- 3 -->
{{ items | first }}                    <!-- first item -->
{{ items | last }}                     <!-- last item -->
{{ items | join: ", " }}               <!-- comma-separated -->
{{ items | reverse }}                  <!-- reversed array -->
{{ items | sort }}                     <!-- sorted array -->
{{ items | sort_by: "name" }}          <!-- sorted by property -->
{{ items | uniq }}                     <!-- unique items -->
```

### Math Filters

```liquid
{{ 5 | plus: 3 }}                      <!-- 8 -->
{{ 10 | minus: 3 }}                    <!-- 7 -->
{{ 4 | times: 3 }}                     <!-- 12 -->
{{ 15 | divided_by: 3 }}               <!-- 5 -->
{{ 17 | modulo: 5 }}                   <!-- 2 -->
{{ 3.14159 | round: 2 }}               <!-- 3.14 -->
{{ 3.7 | ceil }}                       <!-- 4 -->
{{ 3.7 | floor }}                      <!-- 3 -->
{{ -5 | abs }}                         <!-- 5 -->
```

### Date Filters

```liquid
{{ "2023-01-01" | date: "%B %d, %Y" }}    <!-- January 01, 2023 -->
{{ "now" | date: "%Y-%m-%d" }}             <!-- current date -->
```

### Utility Filters

```liquid
{{ variable | default: "fallback" }}      <!-- fallback if empty -->
{{ data | json }}                          <!-- JSON representation -->
{{ text | url_encode }}                    <!-- URL encoding -->
{{ html | escape }}                        <!-- HTML escaping -->
```

## Variable Assignment

### Assign Tag

Create variables:

```liquid
{% assign name = "Alice" %}
{% assign full_name = user.first_name | append: " " | append: user.last_name %}
{% assign doubled = number | times: 2 %}

Hello {{ name }}!
Full name: {{ full_name }}
Doubled: {{ doubled }}
```

### Capture Tag

Capture template output into a variable:

```liquid
{% capture greeting %}
  Hello {{ user.name }}, welcome to {{ site.title }}!
{% endcapture %}

{{ greeting | upcase }}
```

### Increment and Decrement

```liquid
{% increment counter %}    <!-- 0 first time, then 1, 2, 3... -->
{% decrement counter %}    <!-- 0 first time, then -1, -2, -3... -->
```

### Loop Control

```liquid
{% for item in items %}
  {% if item.hidden %}
    {% continue %}
  {% endif %}

  {{ item.name }}

  {% if item.stop_after %}
    {% break %}
  {% endif %}
{% endfor %}
```

## Comments

### Comment Blocks

```liquid
{% comment %}
This is a comment that won't appear in the output.
It can span multiple lines.
{% endcomment %}
```

### Raw Blocks

Prevent Liquid processing:

```liquid
{% raw %}
This {{ won't }} be {% processed %} by Liquid.
{% endraw %}
```

## Advanced Features

### Cycle Tag

Cycle through values:

```liquid
{% for item in items %}
  <div class="{% cycle 'odd', 'even' %}">{{ item }}</div>
{% endfor %}
```

### Liquid Tag

Group multiple statements. Each non-empty line inside the block is parsed as a normal Liquid tag statement:

```liquid
{% liquid
  assign name = user.first_name
  assign greeting = "Hello " | append: name
  if user.premium
    assign greeting = greeting | append: " (Premium)"
  endif
%}

{{ greeting }}
```

### Debug Tag

When debugging is enabled through `DebugConfiguration`, the `debug` tag emits a message through the configured debug output handler and returns no template output:

```liquid
{% debug %}
{% debug product.title %}
```

### Boolean Operations

```liquid
{% if user.active and user.verified %}
  Fully activated user
{% endif %}

{% if user.admin or user.moderator %}
  Has special permissions
{% endif %}
```

### Comparison Operators

```liquid
{% if user.age >= 18 %}           <!-- greater than or equal -->
{% if items.size > 0 %}           <!-- greater than -->
{% if user.name == "admin" %}     <!-- equal -->
{% if user.role != "guest" %}     <!-- not equal -->
{% if user.score <= 100 %}       <!-- less than or equal -->
{% if user.attempts < 3 %}       <!-- less than -->
```

### Contains Operator

```liquid
{% if user.roles contains "admin" %}
  Admin access granted
{% endif %}

{% if user.name contains "john" %}
  Name contains john
{% endif %}
```

## Best Practices

### 1. Use Meaningful Variable Names

```liquid
<!-- Good -->
{% assign user_display_name = user.first_name | append: " " | append: user.last_name %}

<!-- Avoid -->
{% assign n = user.first_name | append: " " | append: user.last_name %}
```

### 2. Handle Missing Values

```liquid
{{ user.name | default: "Anonymous" }}
{{ user.avatar | default: "/images/default-avatar.png" }}
```

### 3. Use Filters Efficiently

```liquid
<!-- Efficient -->
{{ items | size }}

<!-- Less efficient -->
{% assign count = 0 %}
{% for item in items %}
  {% assign count = count | plus: 1 %}
{% endfor %}
{{ count }}
```

### 4. Organize Complex Logic

```liquid
{% liquid
  assign is_authenticated = user.id != blank
  assign is_admin = user.roles contains "admin"
  assign can_edit = is_authenticated and is_admin
%}

{% if can_edit %}
  <button>Edit</button>
{% endif %}
```

## Error Handling

### Safe Navigation

Handle missing properties gracefully:

```liquid
{{ user.profile.bio | default: "No bio available" }}
```

### Conditional Checks

```liquid
{% if user.profile %}
  Bio: {{ user.profile.bio }}
{% else %}
  No profile information
{% endif %}
```

## Performance Tips

### 1. Minimize Loop Complexity

```liquid
<!-- Avoid nested loops when possible -->
{% for category in categories %}
  {% for product in category.products %}
    <!-- Complex rendering -->
  {% endfor %}
{% endfor %}

<!-- Consider flattening data structure -->
{% for product in all_products %}
  {{ product.category_name }}: {{ product.name }}
{% endfor %}
```

### 2. Use Appropriate Filters

```liquid
<!-- Use size filter instead of counting -->
{{ items | size }}

<!-- Use first/last filters -->
{{ items | first }}
{{ items | last }}
```

### 3. Limit Loop Iterations

```liquid
{% for item in items limit: 10 %}
  {{ item }}
{% endfor %}
```

## See Also

- <doc:GettingStarted>
- <doc:PerformanceGuide>
- <doc:CustomFilters>
- <doc:Architecture>
