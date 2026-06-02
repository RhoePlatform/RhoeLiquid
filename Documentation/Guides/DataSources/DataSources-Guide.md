# RhoeLiquid Data Sources Guide

RhoeLiquid's data source system provides a powerful, unified way to load and work with external data in your Liquid templates. This guide covers everything you need to know about using data sources effectively.

## Table of Contents

1. [Overview](#overview)
2. [Basic Usage](#basic-usage)
3. [Supported Formats](#supported-formats)
4. [Loading Data](#loading-data)
5. [Data Filters](#data-filters)
6. [Advanced Patterns](#advanced-patterns)
7. [Performance Tips](#performance-tips)
8. [Creating Custom Data Sources](#creating-custom-data-sources)

## Overview

The data source system allows you to:
- Load data from multiple formats (JSON, Markdown, CSV, etc.)
- Access data uniformly regardless of source format
- Filter and transform data using powerful filters
- Cache data for better performance
- Validate data against schemas

## Basic Usage

### Loading Data in Templates

The primary way to load data is using the `{% data %}` tag with the `load()` function:

```liquid
{% data users = load("./data/users.json") %}

<ul>
{% for user in users %}
  <li>{{ user.name }} - {{ user.email }}</li>
{% endfor %}
</ul>
```

### Loading with Options

You can pass options to control loading behavior:

```liquid
{% data posts = load("./blog/posts.json", cache: 3600) %}
```

## Supported Formats

### JSON (`.json`, `.jsonc`, `.json5`)

Standard JSON with support for comments and JSON5 extensions:

```liquid
{% data config = load("./config.json") %}
{{ config.theme.name }}
```

**Features:**
- JSON with Comments (JSONC)
- JSON5 syntax (trailing commas, unquoted keys)
- Schema validation support
- Network loading with headers

### Markdown (`.md`, `.markdown`, `.mdx`)

Markdown files with YAML/TOML frontmatter:

```liquid
{% data post = load("./blog/my-post.md") %}
<article>
  <h1>{{ post.title }}</h1>
  <time>{{ post.date | date: "%B %d, %Y" }}</time>
  {{ post.content | markdownify }}
</article>
```

**Structure:**
- Frontmatter fields at root level
- `content`: Markdown body without frontmatter
- `excerpt`: Auto-extracted summary
- `raw`: Original file with frontmatter

### CSV (`.csv`, `.tsv`, `.tab`)

Comma and tab-separated files with smart parsing:

```liquid
{% data sales = load("./data/sales.csv") %}
Total: ${{ sales | map: "amount" | sum }}
```

**Features:**
- Automatic delimiter detection
- Header row detection
- Type inference (numbers, booleans, dates)
- RFC 4180 compliant parsing

## Loading Data

### Local Files

```liquid
{% data users = load("./users.json") %}
{% data readme = load("../README.md") %}
{% data data = load("/absolute/path/data.csv") %}
```

### Remote URLs

```liquid
{% data weather = load("https://api.weather.com/current.json",
                      headers: {"API-Key": "your-key"},
                      timeout: 10) %}
```

### Glob Patterns (Future)

```liquid
{% data posts = load("./blog/**/*.md") %}
{% data configs = load("./config/*.{json,yaml}") %}
```

## Data Filters

RhoeLiquid provides powerful filters for working with loaded data:

### where

Filter arrays by condition:

```liquid
{% data users = load("./users.json") %}
{% assign active_users = users | where: "status", "active" %}
{% assign adults = users | where: "age", ">=", 18 %}
```

### map

Extract specific fields:

```liquid
{% assign emails = users | map: "email" %}
{% assign names = users | map: "profile.name" %}
```

### group_by

Group items by a field:

```liquid
{% assign by_role = users | group_by: "role" %}
{% for group in by_role %}
  <h2>{{ group.key }}</h2>
  <ul>
    {% for user in group.items %}
      <li>{{ user.name }}</li>
    {% endfor %}
  </ul>
{% endfor %}
```

### sort_by

Sort arrays by field:

```liquid
{% assign sorted_posts = posts | sort_by: "date" | reverse %}
```

### find

Find first matching item:

```liquid
{% assign admin = users | find: "role", "admin" %}
{{ admin.name }}
```

### sum

Sum numeric values:

```liquid
Total sales: ${{ orders | map: "total" | sum }}
```

### pluck

Extract nested values:

```liquid
{% assign cities = users | pluck: "address.city" %}
```

### limit & offset

Pagination support:

```liquid
{% assign page_items = items | offset: 20 | limit: 10 %}
```

## Advanced Patterns

### Content Collections

Load and work with collections of content:

```liquid
{% data posts = load("./blog/*.md") %}
{% assign recent = posts | sort_by: "date" | reverse | limit: 5 %}
{% assign by_tag = posts | group_by: "tags" %}
```

### Data Validation

Validate data against schemas:

```liquid
{% data users = load("./users.json", 
                    schema: load("./schemas/user.json")) %}
```

### Caching Strategies

```liquid
<!-- Cache for 1 hour -->
{% data api_data = load("https://api.example.com/data", cache: 3600) %}

<!-- Cache indefinitely -->
{% data static_data = load("./config.json", cache: 0) %}

<!-- No caching (default) -->
{% data live_data = load("./live.json") %}
```

### Error Handling

```liquid
{% data users = load("./users.json") %}
{% if users %}
  <!-- Process users -->
{% else %}
  <p>Failed to load user data</p>
{% endif %}
```

## Performance Tips

### 1. Use Caching Wisely

Cache data that doesn't change frequently:

```liquid
{% data config = load("./config.json", cache: 0) %}
{% data posts = load("./posts.json", cache: 3600) %}
```

### 2. Filter Early

Apply filters as early as possible to reduce data size:

```liquid
<!-- Good: Filter immediately -->
{% data active = load("./users.json") | where: "active", true %}

<!-- Less efficient: Filter later -->
{% data all_users = load("./users.json") %}
{% assign active = all_users | where: "active", true %}
```

### 3. Load Only What You Need

If possible, structure your data to avoid loading unnecessary information:

```liquid
<!-- Better: Load specific data -->
{% data user_names = load("./user-names.json") %}

<!-- Worse: Load everything and extract -->
{% data users = load("./users-full.json") %}
{% assign names = users | map: "name" %}
```

### 4. Use Appropriate Formats

- **JSON**: Best for structured data, API responses
- **CSV**: Best for tabular data, spreadsheet exports
- **Markdown**: Best for content with metadata

## Creating Custom Data Sources

To support additional formats, implement the `DataSource` protocol:

```swift
import LiquidCore

struct XMLDataSource: DataSource {
    var supportedExtensions: [String] { 
        ["xml", "html"] 
    }
    
    func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        let data = try Data(contentsOf: url)
        
        // Parse XML
        let xml = try XMLParser.parse(data)
        
        // Convert to DataValue
        return convertToDataValue(xml)
    }
}

// Register with the system
let registry = DataLoaderRegistry.shared
await registry.register(XMLDataSource())
```

## Best Practices

1. **Structure Data Appropriately**: Design your data files with template usage in mind
2. **Use Meaningful File Names**: Help future maintainers understand data purpose
3. **Document Data Schemas**: Keep schema documentation near data files
4. **Version Your Data**: Consider versioning for APIs and changing data formats
5. **Handle Missing Data**: Always check if data loaded successfully
6. **Optimize File Sizes**: Keep data files reasonably sized for performance

## Examples

### Blog System

```liquid
{% data posts = load("./blog/*.md") %}
{% assign published = posts | where: "published", true | sort_by: "date" | reverse %}

<div class="blog">
  {% for post in published %}
    <article>
      <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
      <time>{{ post.date | date: "%B %d, %Y" }}</time>
      <div class="excerpt">{{ post.excerpt }}</div>
      <div class="tags">
        {% for tag in post.tags %}
          <span class="tag">{{ tag }}</span>
        {% endfor %}
      </div>
    </article>
  {% endfor %}
</div>
```

### Product Catalog

```liquid
{% data products = load("./products.csv") %}
{% assign categories = products | group_by: "category" %}

{% for cat in categories %}
  <section>
    <h2>{{ cat.key }}</h2>
    <div class="products">
      {% for product in cat.items | sort_by: "price" %}
        <div class="product">
          <h3>{{ product.name }}</h3>
          <p class="price">${{ product.price }}</p>
          <p>{{ product.description }}</p>
        </div>
      {% endfor %}
    </div>
  </section>
{% endfor %}
```

### API Integration

```liquid
{% data weather = load("https://api.openweathermap.org/data/2.5/weather?q=London",
                      headers: {"X-API-Key": "your-api-key"},
                      cache: 600) %}

<div class="weather">
  <h2>{{ weather.name }}</h2>
  <p>{{ weather.weather[0].description | capitalize }}</p>
  <p>Temperature: {{ weather.main.temp }}°C</p>
  <p>Feels like: {{ weather.main.feels_like }}°C</p>
</div>
```

## Troubleshooting

### Common Issues

1. **File Not Found**
   - Check file paths are relative to template location
   - Ensure file extensions are correct
   - Verify file permissions

2. **Parse Errors**
   - Validate JSON syntax
   - Check CSV delimiter consistency
   - Ensure proper frontmatter formatting

3. **Performance Issues**
   - Enable caching for frequently accessed data
   - Reduce file sizes where possible
   - Consider splitting large datasets

4. **Type Mismatches**
   - Use type-safe access: `user.age.intValue`
   - Check data structure with debug output
   - Validate against schemas

## Conclusion

RhoeLiquid's data source system provides a powerful foundation for building data-driven templates. By understanding the available formats, filters, and patterns, you can create sophisticated template systems that are both performant and maintainable.

For more information, see the [API documentation](./API-Reference.md) or explore the [examples](./examples/) directory.