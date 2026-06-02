# RhoeLiquid Data Filters Reference

This reference documents all data manipulation filters available in RhoeLiquid for working with data loaded from external sources.

## Table of Contents

1. [Overview](#overview)
2. [Filter Reference](#filter-reference)
   - [where](#where)
   - [map](#map)
   - [group_by](#group_by)
   - [sort_by](#sort_by)
   - [find](#find)
   - [sum](#sum)
   - [pluck](#pluck)
   - [limit](#limit)
   - [offset](#offset)
3. [Chaining Filters](#chaining-filters)
4. [Performance Considerations](#performance-considerations)

## Overview

Data filters are specialized filters designed to work with structured data loaded via the data source system. They provide SQL-like operations for querying and transforming data within templates.

All filters work with:
- Arrays of objects (most common)
- Arrays of values
- DataValue types from loaded sources

## Filter Reference

### where

Filters an array to include only items matching a condition.

**Syntax:**
```liquid
{{ array | where: field, value }}
{{ array | where: field, operator, value }}
```

**Parameters:**
- `field`: The field name to check (supports dot notation)
- `operator`: Optional comparison operator (`"=="`, `"!="`, `">"`, `"<"`, `">="`, `"<="`, `"contains"`)
- `value`: The value to compare against

**Examples:**

```liquid
<!-- Simple equality -->
{% assign active_users = users | where: "status", "active" %}
{% assign admins = users | where: "role", "admin" %}

<!-- With operators -->
{% assign adults = users | where: "age", ">=", 18 %}
{% assign high_value = orders | where: "total", ">", 1000 %}
{% assign pending = tasks | where: "completed", "!=", true %}

<!-- Nested fields -->
{% assign sf_users = users | where: "address.city", "San Francisco" %}

<!-- Contains operator -->
{% assign tech_posts = posts | where: "tags", "contains", "technology" %}
```

**Returns:** A filtered array containing only matching items

### map

Extracts a specific field from each item in an array.

**Syntax:**
```liquid
{{ array | map: field }}
```

**Parameters:**
- `field`: The field to extract (supports dot notation)

**Examples:**

```liquid
<!-- Simple field extraction -->
{% assign names = users | map: "name" %}
<!-- Result: ["Alice", "Bob", "Charlie"] -->

{% assign emails = users | map: "email" %}
<!-- Result: ["alice@example.com", "bob@example.com"] -->

<!-- Nested field extraction -->
{% assign cities = users | map: "address.city" %}
<!-- Result: ["New York", "San Francisco", "Austin"] -->

<!-- Chaining with other filters -->
{% assign admin_emails = users | where: "role", "admin" | map: "email" %}
```

**Returns:** An array of extracted values

### group_by

Groups array items by a common field value.

**Syntax:**
```liquid
{{ array | group_by: field }}
```

**Parameters:**
- `field`: The field to group by

**Examples:**

```liquid
<!-- Group users by role -->
{% assign users_by_role = users | group_by: "role" %}
<!-- Result: [
  { "key": "admin", "items": [...] },
  { "key": "user", "items": [...] },
  { "key": "guest", "items": [...] }
] -->

<!-- Group posts by category -->
{% assign posts_by_category = posts | group_by: "category" %}

<!-- Using grouped data -->
{% for group in users_by_role %}
  <h2>{{ group.key | capitalize }}</h2>
  <ul>
    {% for user in group.items %}
      <li>{{ user.name }}</li>
    {% endfor %}
  </ul>
{% endfor %}

<!-- Group by nested field -->
{% assign users_by_city = users | group_by: "address.city" %}
```

**Returns:** An array of group objects, each with:
- `key`: The grouping value
- `items`: Array of items in that group

### sort_by

Sorts an array by a specified field.

**Syntax:**
```liquid
{{ array | sort_by: field }}
```

**Parameters:**
- `field`: The field to sort by

**Examples:**

```liquid
<!-- Sort by name (alphabetical) -->
{% assign sorted_users = users | sort_by: "name" %}

<!-- Sort by number -->
{% assign sorted_products = products | sort_by: "price" %}

<!-- Sort by date -->
{% assign sorted_posts = posts | sort_by: "date" %}

<!-- Reverse sort -->
{% assign newest_first = posts | sort_by: "date" | reverse %}

<!-- Sort by nested field -->
{% assign by_city = users | sort_by: "address.city" %}

<!-- Multi-level sorting -->
{% assign sorted = users | sort_by: "role" | sort_by: "name" %}
```

**Returns:** A new sorted array (original unchanged)

**Notes:**
- Sorts in ascending order (use `reverse` filter for descending)
- Strings sort alphabetically
- Numbers sort numerically
- Dates sort chronologically
- Mixed types may produce unexpected results

### find

Finds the first item matching a condition.

**Syntax:**
```liquid
{{ array | find: field, value }}
{{ array | find: field, operator, value }}
```

**Parameters:**
- `field`: The field to check
- `operator`: Optional comparison operator (same as `where`)
- `value`: The value to find

**Examples:**

```liquid
<!-- Find by exact match -->
{% assign admin = users | find: "username", "admin" %}
{% assign order = orders | find: "id", order_id %}

<!-- Find with operators -->
{% assign first_adult = users | find: "age", ">=", 18 %}
{% assign high_priority = tasks | find: "priority", ">", 5 %}

<!-- Find in nested fields -->
{% assign sf_user = users | find: "address.city", "San Francisco" %}

<!-- Check if found -->
{% assign user = users | find: "email", email_param %}
{% if user %}
  Welcome back, {{ user.name }}!
{% else %}
  User not found
{% endif %}
```

**Returns:** The first matching item or `null` if not found

### sum

Calculates the sum of numeric values in an array.

**Syntax:**
```liquid
{{ array | sum }}
{{ array | map: field | sum }}
```

**Examples:**

```liquid
<!-- Sum an array of numbers -->
{% assign total = [10, 20, 30] | sum %}
<!-- Result: 60 -->

<!-- Sum a field from objects -->
{% assign total_sales = orders | map: "amount" | sum %}
{% assign total_quantity = items | map: "quantity" | sum %}

<!-- With filtering -->
{% assign paid_total = invoices | where: "status", "paid" | map: "amount" | sum %}

<!-- Formatted output -->
Total: ${{ orders | map: "total" | sum | round: 2 }}

<!-- Calculate statistics -->
{% assign count = users | size %}
{% assign total_age = users | map: "age" | sum %}
{% assign average_age = total_age | divided_by: count %}
```

**Returns:** The sum as a number (integer or float)

**Notes:**
- Non-numeric values are ignored (treated as 0)
- Returns 0 for empty arrays
- Works with both integers and floats

### pluck

Extracts values from a complex path, supporting array indices and nested objects.

**Syntax:**
```liquid
{{ object | pluck: path }}
```

**Parameters:**
- `path`: Dot-notation path with optional array indices

**Examples:**

```liquid
<!-- Simple nested access -->
{% assign city = user | pluck: "address.city" %}

<!-- Array index access -->
{% assign first_tag = post | pluck: "tags.0" %}
{% assign third_item = data | pluck: "items.2.name" %}

<!-- Complex paths -->
{% assign value = data | pluck: "users.0.addresses.1.city" %}

<!-- With variables -->
{% assign field_name = "profile.bio" %}
{% assign bio = user | pluck: field_name %}

<!-- Null-safe access -->
{% assign maybe_value = data | pluck: "might.not.exist" %}
<!-- Returns null instead of error -->
```

**Returns:** The value at the path or `null` if not found

**Notes:**
- More powerful than simple dot notation
- Handles array indices (0-based)
- Returns `null` for invalid paths
- Useful for dynamic field access

### limit

Limits an array to the first N items.

**Syntax:**
```liquid
{{ array | limit: count }}
```

**Parameters:**
- `count`: Maximum number of items to include

**Examples:**

```liquid
<!-- Show first 5 items -->
{% assign top_five = items | limit: 5 %}

<!-- Recent posts -->
{% assign recent = posts | sort_by: "date" | reverse | limit: 10 %}

<!-- Pagination preview -->
<ul>
  {% for item in products | limit: 3 %}
    <li>{{ item.name }}</li>
  {% endfor %}
  {% if products.size > 3 %}
    <li>...and {{ products.size | minus: 3 }} more</li>
  {% endif %}
</ul>

<!-- Top N by criteria -->
{% assign top_sellers = products | sort_by: "sales" | reverse | limit: 10 %}
```

**Returns:** A new array with at most `count` items

### offset

Skips the first N items in an array.

**Syntax:**
```liquid
{{ array | offset: count }}
```

**Parameters:**
- `count`: Number of items to skip

**Examples:**

```liquid
<!-- Skip first 10 items -->
{% assign remaining = items | offset: 10 %}

<!-- Pagination -->
{% assign page = 2 %}
{% assign per_page = 20 %}
{% assign start = page | minus: 1 | times: per_page %}
{% assign page_items = items | offset: start | limit: per_page %}

<!-- Skip and take pattern -->
{% assign middle_items = items | offset: 5 | limit: 10 %}

<!-- Load more pattern -->
{% assign initial = posts | limit: 10 %}
{% assign more = posts | offset: 10 | limit: 10 %}
```

**Returns:** A new array with first `count` items removed

## Chaining Filters

Filters can be chained together for complex operations:

```liquid
<!-- Filter, sort, and limit -->
{% assign featured = products 
  | where: "featured", true 
  | sort_by: "rating" 
  | reverse 
  | limit: 6 %}

<!-- Group and sum -->
{% assign sales_by_category = orders 
  | group_by: "category" 
  | map: "items" %}

{% for group in sales_by_category %}
  {{ group.key }}: ${{ group.items | map: "total" | sum }}
{% endfor %}

<!-- Complex query -->
{% assign result = users 
  | where: "status", "active"
  | where: "age", ">=", 18
  | sort_by: "last_login" 
  | reverse
  | offset: 10
  | limit: 20 %}
```

## Performance Considerations

### Filter Order Matters

Place filters that reduce data size early in the chain:

```liquid
<!-- Good: Filter first, then sort -->
{% assign result = large_array 
  | where: "active", true 
  | sort_by: "name" %}

<!-- Less efficient: Sort everything, then filter -->
{% assign result = large_array 
  | sort_by: "name" 
  | where: "active", true %}
```

### Avoid Redundant Operations

```liquid
<!-- Inefficient: Multiple passes -->
{% assign names = users | map: "name" %}
{% assign emails = users | map: "email" %}

<!-- Better: Single pass if possible -->
{% for user in users %}
  {{ user.name }} - {{ user.email }}
{% endfor %}
```

### Use Appropriate Filters

```liquid
<!-- Use find for single item -->
{% assign user = users | find: "id", user_id %}

<!-- Not where + first -->
{% assign user = users | where: "id", user_id | first %}
```

### Cache Filtered Results

```liquid
<!-- If reusing filtered data, assign it -->
{% assign active_users = users | where: "active", true %}

{% for user in active_users %}
  <!-- First use -->
{% endfor %}

{% assign count = active_users | size %}
<!-- Reuse without re-filtering -->
```

## Common Patterns

### Pagination

```liquid
{% assign page = current_page | default: 1 %}
{% assign per_page = 20 %}
{% assign offset = page | minus: 1 | times: per_page %}

{% assign page_items = all_items 
  | offset: offset 
  | limit: per_page %}

Total pages: {{ all_items.size | divided_by: per_page | ceil }}
```

### Search and Filter

```liquid
{% if search_term %}
  {% assign filtered = products | where: "name", "contains", search_term %}
{% else %}
  {% assign filtered = products %}
{% endif %}

{% if category %}
  {% assign filtered = filtered | where: "category", category %}
{% endif %}
```

### Top N by Group

```liquid
{% assign groups = posts | group_by: "category" %}
{% for group in groups %}
  <h2>{{ group.key }}</h2>
  {% assign top_posts = group.items | sort_by: "views" | reverse | limit: 5 %}
  {% for post in top_posts %}
    {{ post.title }} ({{ post.views }} views)
  {% endfor %}
{% endfor %}
```

## See Also

- [Data Sources Guide](./DataSources-Guide.md)
- [Liquid Filters Reference](./Filters-Reference.md)
- [Template Examples](./examples/)