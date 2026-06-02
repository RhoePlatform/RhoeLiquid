# SQLite Data Source Guide

The SQLite data source enables powerful database queries directly from Liquid templates, perfect for static site generators, desktop applications, and data-driven templates.

## Table of Contents

1. [Overview](#overview)
2. [Security](#security)
3. [Basic Usage](#basic-usage)
4. [Query Modes](#query-modes)
5. [SQL Filters](#sql-filters)
6. [Common Patterns](#common-patterns)
7. [Performance](#performance)
8. [Examples](#examples)

## Overview

The SQLite data source provides:
- **Read-only access** to SQLite databases
- **Parameterized queries** for security
- **Automatic type conversion** to DataValue
- **Schema introspection** capabilities
- **SQL aggregate functions** via filters

Supported file extensions:
- `.db`, `.sqlite`, `.sqlite3`, `.db3`, `.s3db`, `.sl3`

## Security

### Read-Only Mode

The SQLite loader operates in **read-only mode** by default:
- No INSERT, UPDATE, DELETE, or DDL operations
- Safe for use with user-provided databases
- Prevents accidental data modification

### SQL Injection Protection

Always use parameterized queries:

```liquid
<!-- SAFE: Parameterized query -->
{% data users = load("./app.db?query=SELECT * FROM users WHERE age > ?&param1=18") %}

<!-- DANGEROUS: Never concatenate user input -->
<!-- {% data users = load("./app.db?query=SELECT * FROM users WHERE name = '" ~ user_input ~ "'") %} -->
```

## Basic Usage

### Loading Database Schema

```liquid
<!-- List all tables -->
{% data schema = load("./database.db") %}
{% for table in schema %}
  Table: {{ table.name }}
  Type: {{ table.type }}
{% endfor %}
```

### Query a Table

```liquid
<!-- Simple table query -->
{% data users = load("./app.db?table=users") %}

<!-- With limit and offset -->
{% data posts = load("./blog.db?table=posts&limit=10&offset=20") %}

<!-- Display results -->
<table>
  {% for user in users %}
  <tr>
    <td>{{ user.id }}</td>
    <td>{{ user.name }}</td>
    <td>{{ user.email }}</td>
  </tr>
  {% endfor %}
</table>
```

### Execute SQL Queries

```liquid
<!-- Basic SELECT -->
{% data active = load("./app.db?query=SELECT * FROM users WHERE active = 1") %}

<!-- With parameters -->
{% data adults = load("./app.db?query=SELECT * FROM users WHERE age >= ?&param1=18") %}

<!-- Multiple parameters -->
{% data filtered = load("./app.db?query=SELECT * FROM products WHERE price BETWEEN ? AND ?&param1=10&param2=100") %}
```

## Query Modes

### 1. Schema Mode (Default)

Returns information about tables and views:

```liquid
{% data info = load("./database.db") %}
```

Result structure:
```json
[
  {
    "name": "users",
    "type": "table",
    "sql": "CREATE TABLE users (...)"
  },
  {
    "name": "posts_view",
    "type": "view",
    "sql": "CREATE VIEW posts_view AS ..."
  }
]
```

### 2. Table Mode

Query an entire table with optional pagination:

```liquid
{% data products = load("./store.db?table=products&limit=50&offset=0") %}
```

URL parameters:
- `table`: Table name (required)
- `limit`: Maximum rows to return
- `offset`: Number of rows to skip

### 3. Query Mode

Execute custom SQL queries:

```liquid
{% data report = load("./analytics.db?query=SELECT category, COUNT(*) as count FROM sales GROUP BY category") %}
```

URL parameters:
- `query`: SQL SELECT statement (required)
- `param1`, `param2`, etc.: Query parameters

## SQL Filters

### Aggregate Functions

```liquid
<!-- Count -->
{{ users | sql_count }}
{{ orders | sql_count: "status", "pending" }}

<!-- Sum -->
Total revenue: ${{ sales | sql_sum: "amount" }}

<!-- Average -->
Average price: ${{ products | sql_avg: "price" | round: 2 }}

<!-- Min/Max -->
Lowest price: ${{ products | sql_min: "price" }}
Highest price: ${{ products | sql_max: "price" }}
```

### Data Manipulation

```liquid
<!-- Select specific columns -->
{% assign names = users | sql_select: "id", "name", "email" %}

<!-- Join previously loaded row sets -->
{% assign joined = users | sql_join: orders, "users.id = orders.user_id" %}
{{ joined[0].orders.total }}

<!-- Get distinct values -->
{% assign cities = users | sql_distinct: "city" %}

<!-- Combined with standard filters -->
{% assign top_products = products | where: "featured", true | sort_by: "sales" | reverse | limit: 5 %}
```

`sql_join` is an in-memory helper for already loaded row arrays. It keeps the left row shape intact and nests the matched right row under the right table name, or under an explicit alias if you pass `as:`.

```liquid
{% assign joined = users | sql_join: orders, "users.id = orders.user_id", as: "order" %}
{{ joined[0].order.total }}

{% assign left_joined = users | sql_join: orders, "users.id = orders.user_id", type: "left" %}
```

## Common Patterns

### 1. User Listing with Pagination

```liquid
{% assign page = request.page | default: 1 %}
{% assign per_page = 20 %}
{% assign offset = page | minus: 1 | times: per_page %}

{% data users = load("./users.db?table=users&limit=" ~ per_page ~ "&offset=" ~ offset) %}

<div class="users">
  {% for user in users %}
    <div class="user-card">
      <h3>{{ user.name }}</h3>
      <p>{{ user.email }}</p>
      <p>Joined: {{ user.created_at | date: "%B %Y" }}</p>
    </div>
  {% endfor %}
</div>

<!-- Pagination controls -->
<div class="pagination">
  {% if page > 1 %}
    <a href="?page={{ page | minus: 1 }}">Previous</a>
  {% endif %}
  
  Page {{ page }}
  
  {% if users.size == per_page %}
    <a href="?page={{ page | plus: 1 }}">Next</a>
  {% endif %}
</div>
```

### 2. Blog with Categories

```liquid
<!-- Get all posts with author info -->
{% data posts = load("./blog.db?query=SELECT p.*, u.name as author_name FROM posts p JOIN users u ON p.author_id = u.id WHERE p.published = 1 ORDER BY p.created_at DESC") %}

<!-- Group by category -->
{% assign by_category = posts | group_by: "category" %}

{% for group in by_category %}
  <section>
    <h2>{{ group.key }}</h2>
    {% for post in group.items | limit: 5 %}
      <article>
        <h3><a href="/posts/{{ post.slug }}">{{ post.title }}</a></h3>
        <p>By {{ post.author_name }} on {{ post.created_at | date: "%B %d, %Y" }}</p>
        <p>{{ post.excerpt }}</p>
      </article>
    {% endfor %}
  </section>
{% endfor %}
```

### 3. Product Catalog with Filters

```liquid
<!-- Load products with category -->
{% data products = load("./store.db?query=SELECT p.*, c.name as category_name FROM products p JOIN categories c ON p.category_id = c.id") %}

<!-- Apply filters -->
{% if request.category %}
  {% assign products = products | where: "category_name", request.category %}
{% endif %}

{% if request.min_price %}
  {% assign products = products | where: "price", ">=", request.min_price %}
{% endif %}

{% if request.max_price %}
  {% assign products = products | where: "price", "<=", request.max_price %}
{% endif %}

<!-- Sort -->
{% case request.sort %}
  {% when "price_asc" %}
    {% assign products = products | sort_by: "price" %}
  {% when "price_desc" %}
    {% assign products = products | sort_by: "price" | reverse %}
  {% when "name" %}
    {% assign products = products | sort_by: "name" %}
  {% else %}
    {% assign products = products | sort_by: "created_at" | reverse %}
{% endcase %}

<!-- Display -->
<div class="products">
  {% for product in products %}
    <div class="product">
      <h3>{{ product.name }}</h3>
      <p class="price">${{ product.price }}</p>
      <p class="category">{{ product.category_name }}</p>
    </div>
  {% endfor %}
</div>

<!-- Summary -->
<p>
  Showing {{ products | size }} products
  {% if request.category %}in {{ request.category }}{% endif %}
</p>
```

### 4. Analytics Dashboard

```liquid
<!-- Sales by month -->
{% data monthly = load("./analytics.db?query=SELECT strftime('%Y-%m', date) as month, SUM(amount) as total FROM sales GROUP BY month ORDER BY month DESC LIMIT 12") %}

<h2>Monthly Sales</h2>
<table>
  {% for row in monthly %}
  <tr>
    <td>{{ row.month }}</td>
    <td>${{ row.total | round: 2 }}</td>
  </tr>
  {% endfor %}
</table>

<!-- Top products -->
{% data top_products = load("./analytics.db?query=SELECT product_name, SUM(quantity) as units_sold, SUM(amount) as revenue FROM sales GROUP BY product_name ORDER BY revenue DESC LIMIT 10") %}

<h2>Top Products</h2>
<ol>
  {% for product in top_products %}
  <li>
    {{ product.product_name }}: 
    {{ product.units_sold }} units, 
    ${{ product.revenue | round: 2 }}
  </li>
  {% endfor %}
</ol>
```

## Performance

### 1. Use Indexes

Ensure your SQLite database has appropriate indexes:

```sql
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_date ON posts(created_at);
CREATE INDEX idx_products_category ON products(category_id);
```

### 2. Limit Results

Always use LIMIT for large tables:

```liquid
<!-- Good: Limited results -->
{% data recent = load("./db.sqlite?query=SELECT * FROM logs ORDER BY created_at DESC LIMIT 100") %}

<!-- Avoid: Loading entire table -->
{% data all_logs = load("./db.sqlite?table=logs") %}
```

### 3. Cache Queries

Cache expensive queries:

```liquid
<!-- Cache for 1 hour -->
{% data stats = load("./analytics.db?query=SELECT COUNT(*) as total, AVG(amount) as average FROM sales", cache: 3600) %}
```

### 4. Use Projections

Select only needed columns:

```liquid
<!-- Good: Select specific columns -->
{% data users = load("./db.sqlite?query=SELECT id, name, email FROM users") %}

<!-- Avoid: SELECT * -->
{% data users = load("./db.sqlite?query=SELECT * FROM users") %}
```

## Advanced Examples

### 1. Search Implementation

```liquid
{% assign search_term = request.q | default: "" %}

{% if search_term != "" %}
  {% data results = load("./content.db?query=SELECT * FROM articles WHERE title LIKE ? OR content LIKE ?&param1=%" ~ search_term ~ "%&param2=%" ~ search_term ~ "%") %}
  
  <h2>Search Results for "{{ search_term }}"</h2>
  
  {% if results.size > 0 %}
    <p>Found {{ results | size }} results</p>
    
    {% for article in results %}
      <article>
        <h3><a href="/articles/{{ article.id }}">{{ article.title }}</a></h3>
        <p>{{ article.excerpt }}</p>
      </article>
    {% endfor %}
  {% else %}
    <p>No results found.</p>
  {% endif %}
{% endif %}
```

### 2. Related Content

```liquid
<!-- Get current article -->
{% data article = load("./blog.db?query=SELECT * FROM articles WHERE id = ?&param1=" ~ article_id) | first %}

<!-- Get related articles by tags -->
{% data related = load("./blog.db?query=SELECT DISTINCT a.* FROM articles a JOIN article_tags at1 ON a.id = at1.article_id JOIN article_tags at2 ON at1.tag_id = at2.tag_id WHERE at2.article_id = ? AND a.id != ? LIMIT 5&param1=" ~ article_id ~ "&param2=" ~ article_id) %}

<h3>Related Articles</h3>
<ul>
  {% for item in related %}
    <li><a href="/articles/{{ item.id }}">{{ item.title }}</a></li>
  {% endfor %}
</ul>
```

### 3. Statistics and Reports

```liquid
<!-- User statistics -->
{% data user_stats = load("./app.db?query=SELECT COUNT(*) as total_users, COUNT(CASE WHEN active = 1 THEN 1 END) as active_users, COUNT(CASE WHEN created_at > date('now', '-30 days') THEN 1 END) as new_users FROM users") | first %}

<div class="stats">
  <div class="stat">
    <h3>Total Users</h3>
    <p>{{ user_stats.total_users }}</p>
  </div>
  <div class="stat">
    <h3>Active Users</h3>
    <p>{{ user_stats.active_users }}</p>
  </div>
  <div class="stat">
    <h3>New Users (30 days)</h3>
    <p>{{ user_stats.new_users }}</p>
  </div>
</div>
```

## Error Handling

```liquid
{% data users = load("./app.db?table=users") %}

{% if users %}
  <!-- Success: display data -->
  {% for user in users %}
    {{ user.name }}
  {% endfor %}
{% else %}
  <!-- Error: show message -->
  <p>Unable to load user data.</p>
{% endif %}
```

## Best Practices

1. **Always use parameterized queries** for user input
2. **Limit result sets** to prevent memory issues
3. **Cache frequently accessed data** appropriately
4. **Create indexes** for commonly queried columns
5. **Use read-only connections** in production
6. **Validate table/column names** if accepting user input
7. **Monitor query performance** in development

## Limitations

- Read-only access (no writes)
- No transaction support
- No stored procedures
- Limited to SELECT queries
- File-based databases only

## See Also

- [Data Sources Guide](./DataSources-Guide.md)
- [Data Filters Reference](./DataFilters-Reference.md)
- [SQLite Documentation](https://sqlite.org/docs.html)
