# TOML Data Source Guide

The TOML data source provides support for TOML (Tom's Obvious, Minimal Language), a configuration file format designed to be easy to read and write. It's particularly popular in the Rust ecosystem and modern development tools.

## Table of Contents

1. [Overview](#overview)
2. [TOML Syntax](#toml-syntax)
3. [Basic Usage](#basic-usage)
4. [Tables and Nested Tables](#tables-and-nested-tables)
5. [Arrays and Tables Arrays](#arrays-and-tables-arrays)
6. [TOML Filters](#toml-filters)
7. [Common Patterns](#common-patterns)
8. [Best Practices](#best-practices)

## Overview

The TOML data source provides:
- **Human-Friendly**: Minimal syntax, maximum readability
- **Strongly Typed**: Clear distinction between strings, integers, floats, booleans
- **DateTime Support**: First-class support for dates and times
- **Table Organization**: Hierarchical data with clear structure
- **Comments**: Single-line comments with #

Supported file extensions:
- `.toml`

## TOML Syntax

### Basic Types

```toml
# This is a comment

# Strings
title = "TOML Example"
name = 'Tom Preston-Werner'
description = """
Multi-line
string"""

literal_string = '''
C:\Users\nodejs\templates'''

# Numbers
integer = 42
float = 3.14
infinity = inf
nan = nan

# Booleans
enabled = true
debug = false

# Dates and Times
dob = 1979-05-27T07:32:00-08:00
date = 2024-01-15
time = 10:30:00
```

### Tables (Objects)

```toml
# Dot-separated keys
name = "Orange"
physical.color = "orange"
physical.shape = "round"

# Table syntax
[server]
host = "localhost"
port = 8080

[database]
server = "192.168.1.1"
ports = [8001, 8002, 8003]
connection_max = 5000
enabled = true

# Nested tables
[servers.alpha]
ip = "10.0.0.1"
dc = "eqdc10"

[servers.beta]
ip = "10.0.0.2"
dc = "eqdc10"
```

### Arrays

```toml
# Inline arrays
colors = ["red", "yellow", "green"]
numbers = [1, 2, 3]
mixed = ["all", 'strings', """are the same""", '''type''']

# Multi-line arrays
contributors = [
  "Alice <alice@example.com>",
  "Bob <bob@example.com>",
  "Charlie <charlie@example.com>"
]

# Array of tables
[[products]]
name = "Hammer"
sku = 738594937

[[products]]
name = "Nail"
sku = 284758393
color = "gray"
```

## Basic Usage

### Loading TOML Files

```liquid
{% data config = load("./config.toml") %}

Title: {{ config.title }}
Version: {{ config.version }}
```

### Configuration File

```toml
# config.toml
title = "My Application"
version = "1.0.0"

[owner]
name = "John Doe"
email = "john@example.com"

[database]
server = "192.168.1.1"
ports = [8001, 8002, 8003]
connection_max = 5000
enabled = true

[servers]
[servers.alpha]
ip = "10.0.0.1"
dc = "eqdc10"

[servers.beta]
ip = "10.0.0.2"
dc = "eqdc20"
```

```liquid
{% data config = load("./config.toml") %}

<h1>{{ config.title }} v{{ config.version }}</h1>
<p>Maintained by {{ config.owner.name }}</p>

<h2>Database</h2>
<p>Server: {{ config.database.server }}</p>
<p>Max connections: {{ config.database.connection_max }}</p>

<h2>Servers</h2>
{% for server in config.servers %}
  <div>
    {{ server[0] }}: {{ server[1].ip }} ({{ server[1].dc }})
  </div>
{% endfor %}
```

## Tables and Nested Tables

### Standard Tables

```toml
# Define a table
[package]
name = "my-package"
version = "1.0.0"
authors = ["John Doe <john@example.com>"]

# Another table
[dependencies]
serde = "1.0"
tokio = { version = "1.0", features = ["full"] }
```

### Nested Tables

```toml
# Inline table
point = { x = 1, y = 2 }

# Dotted keys
fruit.apple.color = "red"
fruit.apple.taste.sweet = true

# Nested table sections
[a]
b.c = 1
b.d = 2

# Equivalent to:
# a = { b = { c = 1, d = 2 } }
```

## Arrays and Tables Arrays

### Array of Tables

```toml
# Array of tables for products
[[products]]
name = "Laptop"
price = 999.99
categories = ["electronics", "computers"]

  [products.specs]
  cpu = "Intel i7"
  ram = "16GB"
  storage = "512GB SSD"

[[products]]
name = "Mouse"
price = 29.99
categories = ["electronics", "accessories"]

  [products.specs]
  type = "wireless"
  dpi = 1600
```

```liquid
{% data catalog = load("./products.toml") %}

<div class="products">
  {% for product in catalog.products %}
    <div class="product">
      <h3>{{ product.name }}</h3>
      <p>Price: ${{ product.price }}</p>
      
      <h4>Categories:</h4>
      <ul>
        {% for cat in product.categories %}
          <li>{{ cat }}</li>
        {% endfor %}
      </ul>
      
      {% if product.specs %}
        <h4>Specifications:</h4>
        <dl>
          {% for spec in product.specs %}
            <dt>{{ spec[0] }}</dt>
            <dd>{{ spec[1] }}</dd>
          {% endfor %}
        </dl>
      {% endif %}
    </div>
  {% endfor %}
</div>
```

## TOML Filters

### to_toml

Convert data to TOML format:

```liquid
{% assign config = site.config %}
{{ config | to_toml }}

<!-- Output:
title = "My Site"
version = "2.0"

[author]
name = "John Doe"
email = "john@example.com"
-->
```

## Common Patterns

### 1. Rust Project Configuration (Cargo.toml)

```toml
[package]
name = "my-project"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <you@example.com>"]
description = "A brief description"
license = "MIT"
repository = "https://github.com/you/my-project"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1", features = ["full"] }
reqwest = "0.11"

[dev-dependencies]
mockito = "0.31"
criterion = "0.4"

[profile.release]
opt-level = 3
lto = true
```

```liquid
{% data cargo = load("./Cargo.toml") %}

<h1>{{ cargo.package.name }}</h1>
<p>{{ cargo.package.description }}</p>
<p>Version: {{ cargo.package.version }}</p>

<h2>Dependencies</h2>
<ul>
  {% for dep in cargo.dependencies %}
    <li>
      {{ dep[0] }}: 
      {% if dep[1].version %}
        {{ dep[1].version }}
      {% else %}
        {{ dep[1] }}
      {% endif %}
    </li>
  {% endfor %}
</ul>
```

### 2. Python Project Configuration (pyproject.toml)

```toml
[tool.poetry]
name = "my-python-project"
version = "1.0.0"
description = "A Python project"
authors = ["Your Name <you@example.com>"]
readme = "README.md"
packages = [{include = "my_project"}]

[tool.poetry.dependencies]
python = "^3.9"
django = "^4.0"
requests = "^2.28"

[tool.poetry.group.dev.dependencies]
pytest = "^7.0"
black = "^22.0"
mypy = "^0.990"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

```liquid
{% data pyproject = load("./pyproject.toml") %}

<h1>{{ pyproject.tool.poetry.name }}</h1>
<p>{{ pyproject.tool.poetry.description }}</p>

<h2>Requirements</h2>
<ul>
  {% for dep in pyproject.tool.poetry.dependencies %}
    <li>{{ dep[0] }}: {{ dep[1] }}</li>
  {% endfor %}
</ul>

<h2>Development Dependencies</h2>
<ul>
  {% for dep in pyproject.tool.poetry.group.dev.dependencies %}
    <li>{{ dep[0] }}: {{ dep[1] }}</li>
  {% endfor %}
</ul>
```

### 3. Application Settings

```toml
# settings.toml
title = "My Web Application"
debug = false
secret_key = "@ENV:SECRET_KEY"  # Reference environment variable

[server]
host = "0.0.0.0"
port = 8080
workers = 4

[database]
url = "postgresql://user:pass@localhost/myapp"
max_connections = 100
timeout = 30

[cache]
backend = "redis"
  [cache.redis]
  host = "localhost"
  port = 6379
  db = 0

[logging]
level = "INFO"
format = "json"

  [[logging.handlers]]
  type = "file"
  filename = "/var/log/myapp.log"
  max_bytes = 10485760  # 10MB
  backup_count = 5

  [[logging.handlers]]
  type = "console"
  stream = "stdout"
```

```liquid
{% data settings = load("./settings.toml") %}

<!-- Check debug mode -->
{% if settings.debug %}
  <div class="debug-banner">Debug mode is ON</div>
{% endif %}

<!-- Server configuration -->
<p>Server: {{ settings.server.host }}:{{ settings.server.port }}</p>
<p>Workers: {{ settings.server.workers }}</p>

<!-- Logging setup -->
<h3>Logging Configuration</h3>
<p>Level: {{ settings.logging.level }}</p>
<ul>
  {% for handler in settings.logging.handlers %}
    <li>{{ handler.type | capitalize }} handler
      {% if handler.filename %}
        - {{ handler.filename }}
      {% endif %}
    </li>
  {% endfor %}
</ul>
```

### 4. Site Navigation

```toml
# navigation.toml
[[nav]]
name = "Home"
url = "/"
icon = "home"

[[nav]]
name = "Products"
url = "/products"
icon = "shopping-cart"

  [[nav.children]]
  name = "Electronics"
  url = "/products/electronics"
  
  [[nav.children]]
  name = "Books"
  url = "/products/books"

[[nav]]
name = "About"
url = "/about"
icon = "info"

[[nav]]
name = "Contact"
url = "/contact"
icon = "mail"
```

```liquid
{% data nav = load("./navigation.toml") %}

<nav>
  {% for item in nav.nav %}
    <div class="nav-item">
      <a href="{{ item.url }}">
        <i class="icon-{{ item.icon }}"></i>
        {{ item.name }}
      </a>
      
      {% if item.children %}
        <ul class="dropdown">
          {% for child in item.children %}
            <li>
              <a href="{{ child.url }}">{{ child.name }}</a>
            </li>
          {% endfor %}
        </ul>
      {% endif %}
    </div>
  {% endfor %}
</nav>
```

## Best Practices

### 1. Use Clear Section Names

```toml
# Good
[database]
host = "localhost"

[cache]
type = "redis"

# Avoid
[db]
h = "localhost"

[c]
t = "redis"
```

### 2. Group Related Settings

```toml
# Good - grouped by feature
[api]
key = "abc123"
timeout = 30
max_retries = 3

[api.endpoints]
users = "/api/v1/users"
posts = "/api/v1/posts"

# Avoid - scattered configuration
api_key = "abc123"
users_endpoint = "/api/v1/users"
api_timeout = 30
posts_endpoint = "/api/v1/posts"
api_max_retries = 3
```

### 3. Use Appropriate Types

```toml
# Good - using appropriate types
port = 8080  # integer
rate = 0.95  # float
enabled = true  # boolean
name = "app"  # string

# Avoid - everything as strings
port = "8080"
rate = "0.95"
enabled = "true"
```

### 4. Document with Comments

```toml
# Application configuration file
# Last updated: 2024-01-15

[server]
# The host to bind to (use 0.0.0.0 for all interfaces)
host = "127.0.0.1"

# Port number (must be between 1024-65535 for non-root)
port = 8080

# Number of worker processes
# Set to 0 for auto-detection based on CPU cores
workers = 4
```

### 5. Use Tables for Namespacing

```toml
# Good - clear namespace hierarchy
[production]
[production.database]
host = "prod-db.example.com"
port = 5432

[production.cache]
host = "prod-cache.example.com"
port = 6379

[development]
[development.database]
host = "localhost"
port = 5432

[development.cache]
host = "localhost"
port = 6379
```

## Comparison with Other Formats

### TOML vs YAML

```toml
# TOML - explicit and unambiguous
string = "hello"
number = 42
enabled = true

[server]
host = "localhost"
port = 8080
```

```yaml
# YAML - more compact but can be ambiguous
string: hello  # Is this a string or boolean?
number: 42
enabled: yes   # Or true? Or "yes"?

server:
  host: localhost
  port: 8080
```

### TOML vs JSON

```toml
# TOML - human-friendly
title = "My App"
debug = true

[database]
host = "localhost"
port = 5432
```

```json
// JSON - machine-friendly but verbose
{
  "title": "My App",
  "debug": true,
  "database": {
    "host": "localhost",
    "port": 5432
  }
}
```

## Limitations

1. **No References**: Unlike YAML, TOML doesn't support anchors/aliases
2. **No Multi-line Keys**: Keys must be on a single line
3. **Limited Nesting**: Deep nesting can become unwieldy
4. **Array Restrictions**: Arrays must be homogeneous

## Security Considerations

1. **Type Safety**: TOML's strong typing prevents many parsing ambiguities
2. **No Code Execution**: TOML is pure data, no executable content
3. **Size Limits**: Be mindful of large TOML files' memory usage
4. **Input Validation**: Always validate loaded configuration

## See Also

- [Data Sources Guide](./DataSources-Guide.md)
- [Data Filters Reference](./DataFilters-Reference.md)
- [TOML Specification](https://toml.io/)