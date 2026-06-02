# RhoeLiquid Data Sources Best Practices

This guide provides best practices and recommendations for effectively using RhoeLiquid's data source system in production applications.

## Table of Contents

1. [Data Organization](#data-organization)
2. [Performance Optimization](#performance-optimization)
3. [Security Considerations](#security-considerations)
4. [Error Handling](#error-handling)
5. [Caching Strategies](#caching-strategies)
6. [Schema Design](#schema-design)
7. [Content Management](#content-management)
8. [API Integration](#api-integration)
9. [Testing and Development](#testing-and-development)
10. [Migration and Versioning](#migration-and-versioning)

## Data Organization

### File Structure

Organize your data files logically and consistently:

```
project/
├── data/
│   ├── config/
│   │   ├── site.json
│   │   ├── navigation.json
│   │   └── features.json
│   ├── content/
│   │   ├── posts/
│   │   ├── pages/
│   │   └── authors/
│   └── api/
│       ├── products.json
│       └── inventory.csv
├── templates/
└── schemas/
```

### Naming Conventions

- Use descriptive, lowercase filenames: `user-profiles.json`, not `data1.json`
- Include type indicators when helpful: `users-list.json`, `user-detail.json`
- Use consistent pluralization: `posts/` for collections, `post.md` for singles
- Date-prefix time-sensitive data: `2024-01-sales.csv`

### Data Granularity

**Do:** Split data appropriately
```liquid
<!-- Good: Separate files for different concerns -->
{% data navigation = load("./data/navigation.json") %}
{% data products = load("./data/products.json") %}
```

**Don't:** Create monolithic data files
```liquid
<!-- Bad: Everything in one file -->
{% data everything = load("./data/all-site-data.json") %}
```

## Performance Optimization

### 1. Minimize Data Loading

Load only what you need:

```liquid
<!-- Good: Load specific data -->
{% data featured = load("./data/featured-products.json") %}

<!-- Avoid: Loading all data and filtering -->
{% data all_products = load("./data/products-complete.json") %}
{% assign featured = all_products | where: "featured", true %}
```

### 2. Use Caching Strategically

```liquid
<!-- Static data: Cache indefinitely -->
{% data config = load("./config.json", cache: 0) %}

<!-- Frequently changing: Short cache -->
{% data inventory = load("./inventory.json", cache: 300) %}

<!-- Real-time: No cache -->
{% data live_prices = load("https://api.example.com/prices") %}
```

### 3. Optimize Data Structures

Design data for efficient access:

```json
// Good: Flat structure for common access patterns
{
  "products": [
    {
      "id": "123",
      "name": "Widget",
      "price": 29.99,
      "category_id": "tools"
    }
  ]
}

// Avoid: Deeply nested structures
{
  "categories": {
    "tools": {
      "subcategories": {
        "hand-tools": {
          "products": [...]
        }
      }
    }
  }
}
```

### 4. Batch Operations

Combine related data operations:

```liquid
<!-- Good: Single load for related data -->
{% data blog_data = load("./data/blog-bundle.json") %}
{% assign posts = blog_data.posts %}
{% assign authors = blog_data.authors %}
{% assign categories = blog_data.categories %}

<!-- Avoid: Multiple loads -->
{% data posts = load("./data/posts.json") %}
{% data authors = load("./data/authors.json") %}
{% data categories = load("./data/categories.json") %}
```

## Security Considerations

### 1. Validate External Data

Always validate data from external sources:

```liquid
{% data api_response = load(api_url, 
  schema: load("./schemas/api-response.json")) %}

{% if api_response %}
  <!-- Process validated data -->
{% else %}
  <!-- Handle validation failure -->
{% endif %}
```

### 2. Sanitize User Input

Never directly use user input in data paths:

```liquid
<!-- DANGER: Path traversal vulnerability -->
{% data user_file = load(request.params.file) %}

<!-- Safe: Whitelist approach -->
{% case request.params.type %}
  {% when "products" %}
    {% data items = load("./data/products.json") %}
  {% when "posts" %}
    {% data items = load("./data/posts.json") %}
  {% else %}
    {% assign items = null %}
{% endcase %}
```

### 3. Protect Sensitive Data

- Never commit API keys or credentials to data files
- Use environment variables for sensitive configuration
- Implement proper access controls on data files
- Consider encryption for sensitive data at rest

### 4. Rate Limiting

Implement rate limiting for external APIs:

```liquid
<!-- Use caching to respect rate limits -->
{% data api_data = load("https://api.example.com/data",
  cache: 3600,
  headers: {"X-API-Key": env.API_KEY}) %}
```

## Error Handling

### 1. Graceful Degradation

Always handle missing or invalid data:

```liquid
{% data products = load("./data/products.json") %}
{% if products %}
  {% for product in products %}
    <!-- Display products -->
  {% endfor %}
{% else %}
  <p>Products are temporarily unavailable.</p>
{% endif %}
```

### 2. Provide Fallbacks

```liquid
{% data user_prefs = load("./data/user-prefs.json") %}
{% assign theme = user_prefs.theme | default: "light" %}
{% assign language = user_prefs.language | default: "en" %}
```

### 3. Log Errors Appropriately

```liquid
{% data config = load("./config.json") %}
{% unless config %}
  {% log level: "error", message: "Failed to load critical config.json" %}
  {% assign config = site.default_config %}
{% endunless %}
```

## Caching Strategies

### 1. Cache Duration Guidelines

| Data Type | Cache Duration | Example |
|-----------|---------------|---------|
| Static Config | Indefinite (0) | Site settings, feature flags |
| Content | 1-24 hours | Blog posts, product descriptions |
| Inventory | 5-15 minutes | Stock levels, availability |
| Prices | 1-5 minutes | Dynamic pricing, exchange rates |
| User Data | No cache | Personal information, cart |

### 2. Cache Invalidation

Plan for cache invalidation:

```liquid
<!-- Version your cache keys -->
{% assign cache_version = "v2" %}
{% data products = load("./data/products.json", 
  cache: 3600, 
  cache_key: "products-" | append: cache_version) %}
```

### 3. Conditional Caching

```liquid
{% if user.is_logged_in %}
  <!-- No cache for personalized data -->
  {% data recommendations = load(user_recommendations_url) %}
{% else %}
  <!-- Cache for anonymous users -->
  {% data recommendations = load("./data/default-recommendations.json", 
    cache: 1800) %}
{% endif %}
```

## Schema Design

### 1. Consistent Structure

Define and maintain consistent data structures:

```json
// product.schema.json
{
  "type": "object",
  "required": ["id", "name", "price"],
  "properties": {
    "id": { "type": "string" },
    "name": { "type": "string" },
    "price": { "type": "number", "minimum": 0 },
    "description": { "type": "string" },
    "category": { "type": "string" },
    "tags": { 
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
```

### 2. Version Your Schemas

```liquid
{% data products = load("./data/products-v2.json",
  schema: load("./schemas/product-v2.schema.json")) %}
```

### 3. Document Field Purposes

```yaml
# Schema documentation
fields:
  - name: "sku"
    type: "string"
    description: "Stock Keeping Unit - unique product identifier"
    example: "WIDG-001"
  
  - name: "available_date"
    type: "date"
    description: "When product becomes available for purchase"
    format: "ISO 8601"
```

## Content Management

### 1. Frontmatter Standards

Establish consistent frontmatter fields:

```markdown
---
# Required fields
title: "Post Title"
date: 2024-01-15
author: "jane-doe"

# Optional fields
category: "tutorials"
tags: ["liquid", "templates"]
featured: false
excerpt: "Custom excerpt..."

# SEO fields
meta_description: "..."
og_image: "./images/hero.jpg"
---
```

### 2. Content Collections

Structure collections for easy querying:

```liquid
{% data posts = load("./content/posts/*.md") %}

<!-- Easy filtering by frontmatter -->
{% assign tutorials = posts | where: "category", "tutorials" %}
{% assign recent = posts | where: "date", ">", last_week | sort_by: "date" | reverse %}
{% assign featured = posts | where: "featured", true | limit: 3 %}
```

### 3. Content Relationships

Link related content efficiently:

```yaml
# post.md
---
title: "Advanced Liquid Templates"
author_id: "jane-doe"
related_posts: ["liquid-basics", "template-inheritance"]
---

# author.md
---
id: "jane-doe"
name: "Jane Doe"
bio: "..."
---
```

```liquid
{% data posts = load("./posts/*.md") %}
{% data authors = load("./authors/*.md") %}

{% for post in posts %}
  {% assign author = authors | find: "id", post.author_id %}
  By {{ author.name }}
{% endfor %}
```

## API Integration

### 1. API Response Caching

```liquid
<!-- Cache based on API update frequency -->
{% data weather = load("https://api.weather.com/current",
  headers: {"API-Key": env.WEATHER_API_KEY},
  cache: 600) %}  <!-- 10 minutes -->
```

### 2. Timeout Configuration

```liquid
<!-- Set appropriate timeouts -->
{% data quick_api = load("https://fast-api.com/data",
  timeout: 5) %}  <!-- 5 seconds -->

{% data slow_api = load("https://slow-api.com/report",
  timeout: 30) %}  <!-- 30 seconds -->
```

### 3. Error Recovery

```liquid
<!-- Primary and fallback -->
{% data prices = load("https://primary-api.com/prices",
  timeout: 5,
  cache: 60) %}

{% unless prices %}
  {% data prices = load("https://backup-api.com/prices",
    timeout: 10) %}
{% endunless %}

{% unless prices %}
  {% data prices = load("./data/cached-prices.json") %}
{% endunless %}
```

## Testing and Development

### 1. Test Data Sets

Maintain separate test data:

```
data/
├── production/
│   └── products.json
├── staging/
│   └── products.json
└── test/
    ├── products-minimal.json
    ├── products-edge-cases.json
    └── products-performance.json
```

### 2. Development Helpers

```liquid
{% if site.environment == "development" %}
  {% data test_data = load("./data/test/sample.json") %}
  <pre>{{ test_data | json }}</pre>
{% endif %}
```

### 3. Performance Monitoring

```liquid
{% capture start_time %}{{ "now" | date: "%s" }}{% endcapture %}
{% data large_dataset = load("./data/products.json") %}
{% capture end_time %}{{ "now" | date: "%s" }}{% endcapture %}

{% if site.debug %}
  <!-- Load time: {{ end_time | minus: start_time }}s -->
{% endif %}
```

## Migration and Versioning

### 1. Data Format Versioning

```liquid
{% data config = load("./config.json") %}
{% case config.version %}
  {% when 1 %}
    {% include "parsers/config-v1.liquid" %}
  {% when 2 %}
    {% include "parsers/config-v2.liquid" %}
  {% else %}
    {% error "Unsupported config version" %}
{% endcase %}
```

### 2. Gradual Migration

```liquid
<!-- Support both old and new formats -->
{% data users = load("./users.json") %}
{% if users.format_version %}
  <!-- New format -->
  {% assign user_list = users.data %}
{% else %}
  <!-- Old format -->
  {% assign user_list = users %}
{% endif %}
```

### 3. Backwards Compatibility

```liquid
<!-- Add defaults for new fields -->
{% for product in products %}
  {% assign rating = product.rating | default: 0 %}
  {% assign reviews_count = product.reviews_count | default: 0 %}
{% endfor %}
```

## Monitoring and Debugging

### 1. Debug Output

```liquid
{% if params.debug == "true" %}
  <div class="debug">
    <h3>Loaded Data Sources</h3>
    <pre>{{ data_sources | json }}</pre>
  </div>
{% endif %}
```

### 2. Performance Tracking

```liquid
<!-- Track slow operations -->
{% timer "data_load" %}
  {% data products = load("./products.json") %}
  {% data inventory = load("./inventory.csv") %}
  {% data prices = load("https://api.example.com/prices") %}
{% endtimer %}
```

### 3. Data Validation

```liquid
<!-- Validate critical data -->
{% data products = load("./products.json") %}
{% assign invalid_products = products | where: "price", "<=", 0 %}
{% if invalid_products.size > 0 %}
  {% log level: "warning", message: "Found products with invalid prices", 
    data: invalid_products %}
{% endif %}
```

## Conclusion

Following these best practices will help you build robust, performant, and maintainable applications with RhoeLiquid's data source system. Remember to:

1. **Organize** data logically and consistently
2. **Optimize** for performance from the start
3. **Secure** sensitive data and validate inputs
4. **Handle** errors gracefully
5. **Cache** appropriately for your use case
6. **Document** your data structures
7. **Test** with realistic data sets
8. **Monitor** performance in production

For more details, consult the [Data Sources Guide](./DataSources-Guide.md) and [API Reference](./API-Reference.md).