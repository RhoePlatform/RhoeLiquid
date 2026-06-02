# YAML Data Source Guide

The YAML data source provides comprehensive support for YAML (YAML Ain't Markup Language), a human-friendly data serialization format widely used for configuration files, data exchange, and content management.

## Table of Contents

1. [Overview](#overview)
2. [YAML Syntax](#yaml-syntax)
3. [Basic Usage](#basic-usage)
4. [Advanced Features](#advanced-features)
5. [Multi-Document Support](#multi-document-support)
6. [YAML Filters](#yaml-filters)
7. [Common Patterns](#common-patterns)
8. [Best Practices](#best-practices)

## Overview

The YAML data source provides:
- **Full YAML 1.2 Support**: All features including anchors, aliases, and tags
- **Human-Friendly**: Designed for readability and ease of editing
- **Type Inference**: Automatic detection of strings, numbers, booleans, dates
- **Multi-Document**: Support for multiple YAML documents in one file
- **Merge Operations**: Deep merging of YAML structures

Supported file extensions:
- `.yml`, `.yaml`

## YAML Syntax

### Basic Types

```yaml
# Strings
name: John Doe
description: "A quoted string"
multiline: |
  This is a multi-line
  string that preserves
  line breaks.
folded: >
  This is a folded string
  that will be rendered
  as a single line.

# Numbers
age: 30
price: 19.99
scientific: 1.23e+5

# Booleans
active: true
disabled: false
# Also valid: yes/no, on/off, TRUE/FALSE

# Null values
middle_name: null
alternative: ~

# Dates and times
date: 2024-01-15
datetime: 2024-01-15T10:30:00Z
timestamp: 2024-01-15 10:30:00
```

### Collections

```yaml
# Arrays (Lists)
fruits:
  - apple
  - banana
  - orange

# Inline arrays
numbers: [1, 2, 3, 4, 5]

# Nested arrays
matrix:
  - [1, 2, 3]
  - [4, 5, 6]
  - [7, 8, 9]

# Objects (Mappings)
person:
  name: John Doe
  age: 30
  address:
    street: 123 Main St
    city: Anytown
    country: USA

# Inline objects
coordinates: {x: 10, y: 20, z: 30}
```

## Basic Usage

### Loading YAML Files

```liquid
{% data config = load("./config.yml") %}

Site: {{ config.site.name }}
Version: {{ config.version }}
```

### Configuration Files

```yaml
# config.yml
site:
  name: My Website
  url: https://example.com
  description: A great website

database:
  host: localhost
  port: 5432
  name: myapp
  user: dbuser

features:
  comments: true
  analytics: false
  newsletter: true
```

```liquid
{% data config = load("./config.yml") %}

<h1>{{ config.site.name }}</h1>
<p>{{ config.site.description }}</p>

{% if config.features.comments %}
  <!-- Comments enabled -->
{% endif %}
```

### Data Collections

```yaml
# team.yml
team:
  - name: Alice Johnson
    role: CEO
    email: alice@example.com
    skills:
      - Leadership
      - Strategy
      - Communication
  
  - name: Bob Smith
    role: CTO
    email: bob@example.com
    skills:
      - Architecture
      - Programming
      - DevOps
```

```liquid
{% data team = load("./team.yml") %}

<div class="team">
  {% for member in team.team %}
    <div class="member">
      <h3>{{ member.name }}</h3>
      <p>{{ member.role }}</p>
      <ul>
        {% for skill in member.skills %}
          <li>{{ skill }}</li>
        {% endfor %}
      </ul>
    </div>
  {% endfor %}
</div>
```

## Advanced Features

### Anchors and Aliases

Anchors (`&`) and aliases (`*`) allow you to reuse content:

```yaml
# database.yml
defaults: &defaults
  adapter: postgresql
  encoding: unicode
  pool: 5
  timeout: 5000

development:
  <<: *defaults
  database: myapp_development
  host: localhost

production:
  <<: *defaults
  database: myapp_production
  host: db.example.com
  pool: 25
```

```liquid
{% data db = load("./database.yml") %}

<!-- Both inherit from defaults -->
Dev DB: {{ db.development.database }} ({{ db.development.adapter }})
Prod DB: {{ db.production.database }} ({{ db.production.adapter }})
```

### Complex Structures

```yaml
# products.yml
categories:
  electronics: &electronics_defaults
    warranty: 1 year
    shipping: standard
    
  books: &book_defaults
    returnable: true
    shipping: media

products:
  - id: 1001
    name: Laptop Pro
    price: 1299.99
    category: electronics
    <<: *electronics_defaults
    specs:
      cpu: Intel i7
      ram: 16GB
      storage: 512GB SSD
    
  - id: 2001
    name: "YAML: The Definitive Guide"
    price: 39.99
    category: books
    <<: *book_defaults
    author: Jane Smith
    isbn: 978-1234567890
```

### Tagged Values

YAML supports custom type tags:

```yaml
# Using built-in tags
binary_data: !!binary |
  R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXvPz7Y6OjuDg4J+fn5
  OTk6enp56enmlpaWNjY6Ojo4SEhP/++f/++f/++f/++f/++f/++f/++f/++f/+
  +f/++f/++f/++f/++f/++SH+Dk1hZGUgd2l0aCBHSU1QACwAAAAADAAMAAAFLC
  AgjoEwnuNAFOhpEMTRiggcz4BNJHrv/zCFcLiwMWYNG84BwwEeECcgggoBADs=

# Custom application types
location: !location
  latitude: 37.7749
  longitude: -122.4194
```

## Multi-Document Support

YAML files can contain multiple documents separated by `---`:

```yaml
---
# Document 1
title: First Document
content: This is the first document
---
# Document 2
title: Second Document
content: This is the second document
---
# Document 3
title: Third Document
content: This is the third document
```

```liquid
{% data docs = load("./multi-doc.yml") %}

<!-- docs is an array of documents -->
{% for doc in docs %}
  <article>
    <h2>{{ doc.title }}</h2>
    <p>{{ doc.content }}</p>
  </article>
{% endfor %}
```

## YAML Filters

### yaml_merge

Deep merge YAML structures:

```liquid
{% data defaults = load("./defaults.yml") %}
{% data overrides = load("./overrides.yml") %}

{% assign config = defaults | yaml_merge: overrides %}

<!-- Result has merged configuration -->
{{ config.database.host }}
```

### to_yaml

Convert data to YAML format:

```liquid
{% assign user = site.users | first %}
{{ user | to_yaml }}

<!-- Output:
name: John Doe
email: john@example.com
roles:
  - admin
  - editor
-->
```

## Common Patterns

### 1. Site Configuration

```yaml
# _config.yml
site:
  title: My Amazing Blog
  description: Thoughts on technology and life
  url: https://myblog.com
  author:
    name: John Doe
    email: john@myblog.com
    twitter: "@johndoe"

navigation:
  - name: Home
    url: /
  - name: About
    url: /about
  - name: Blog
    url: /blog
  - name: Contact
    url: /contact

social:
  twitter: https://twitter.com/myblog
  github: https://github.com/myblog
  linkedin: https://linkedin.com/company/myblog

analytics:
  google: UA-123456789
  enabled: true
```

```liquid
{% data site = load("./_config.yml") %}

<!DOCTYPE html>
<html>
<head>
  <title>{{ page.title }} - {{ site.site.title }}</title>
  <meta name="description" content="{{ site.site.description }}">
  <meta name="author" content="{{ site.site.author.name }}">
</head>
<body>
  <nav>
    {% for item in site.navigation %}
      <a href="{{ item.url }}">{{ item.name }}</a>
    {% endfor %}
  </nav>
  
  {{ content }}
  
  <footer>
    {% for social in site.social %}
      <a href="{{ social[1] }}">{{ social[0] | capitalize }}</a>
    {% endfor %}
  </footer>
  
  {% if site.analytics.enabled %}
    <script>
      // Google Analytics: {{ site.analytics.google }}
    </script>
  {% endif %}
</body>
</html>
```

### 2. Content Collections

```yaml
# authors.yml
authors:
  john_doe:
    name: John Doe
    bio: |
      John is a software engineer with over 10 years
      of experience in web development.
    avatar: /images/john.jpg
    social:
      twitter: johndoe
      github: johndoe
  
  jane_smith:
    name: Jane Smith
    bio: |
      Jane is a UX designer passionate about creating
      beautiful and functional user experiences.
    avatar: /images/jane.jpg
    social:
      twitter: janesmith
      dribbble: janesmith
```

```liquid
{% data authors = load("./authors.yml") %}

{% assign author = authors.authors[post.author] %}

<div class="author-bio">
  <img src="{{ author.avatar }}" alt="{{ author.name }}">
  <h3>{{ author.name }}</h3>
  <p>{{ author.bio }}</p>
  
  <div class="social">
    {% for social in author.social %}
      <a href="https://{{ social[0] }}.com/{{ social[1] }}">
        {{ social[0] | capitalize }}
      </a>
    {% endfor %}
  </div>
</div>
```

### 3. Localization

```yaml
# i18n/en.yml
en:
  welcome: Welcome
  navigation:
    home: Home
    about: About Us
    contact: Contact
  messages:
    success: Operation completed successfully
    error: An error occurred
    loading: Loading...
  
# i18n/es.yml
es:
  welcome: Bienvenido
  navigation:
    home: Inicio
    about: Sobre Nosotros
    contact: Contacto
  messages:
    success: Operación completada con éxito
    error: Ocurrió un error
    loading: Cargando...
```

```liquid
{% assign lang = page.lang | default: "en" %}
{% data translations = load("./i18n/" ~ lang ~ ".yml") %}
{% assign t = translations[lang] %}

<h1>{{ t.welcome }}</h1>

<nav>
  <a href="/">{{ t.navigation.home }}</a>
  <a href="/about">{{ t.navigation.about }}</a>
  <a href="/contact">{{ t.navigation.contact }}</a>
</nav>
```

### 4. Feature Flags

```yaml
# features.yml
features:
  new_design:
    enabled: true
    rollout_percentage: 100
    
  dark_mode:
    enabled: true
    default: false
    
  comments:
    enabled: true
    providers:
      - disqus
      - native
    default_provider: disqus
    
  search:
    enabled: false
    engine: elasticsearch
```

```liquid
{% data features = load("./features.yml") %}

{% if features.features.dark_mode.enabled %}
  <button id="dark-mode-toggle">
    Toggle Dark Mode
  </button>
{% endif %}

{% if features.features.comments.enabled %}
  {% case features.features.comments.default_provider %}
    {% when "disqus" %}
      <!-- Disqus comments -->
    {% when "native" %}
      <!-- Native comments -->
  {% endcase %}
{% endif %}
```

## Best Practices

### 1. Use Meaningful Keys

```yaml
# Good
database:
  primary:
    host: db1.example.com
    port: 5432

# Avoid
db:
  p:
    h: db1.example.com
    p: 5432
```

### 2. Consistent Indentation

Always use spaces (not tabs) and be consistent:

```yaml
# Good - 2 spaces
server:
  host: localhost
  port: 8080
  
# Bad - mixed indentation
server:
    host: localhost
  port: 8080
```

### 3. Quote Special Strings

```yaml
# Quote strings that could be misinterpreted
version: "1.0"  # Not 1.0 (float)
enabled: "yes"  # Not yes (boolean)
zip: "01234"    # Not 1234 (number)
```

### 4. Use Anchors for DRY

```yaml
# Define once, use many times
defaults: &defaults
  timeout: 30
  retries: 3
  
service_a:
  <<: *defaults
  url: https://a.example.com
  
service_b:
  <<: *defaults
  url: https://b.example.com
```

### 5. Organize Large Files

```yaml
# Use clear sections
# ====================
# Application Settings
# ====================
app:
  name: MyApp
  version: 2.0

# ====================
# Database Settings
# ====================
database:
  host: localhost
  port: 5432
```

### 6. Validate YAML

Always validate your YAML files:

```liquid
{% data config = load("./config.yml") %}

{% if config == null %}
  <p>Error: Failed to load configuration</p>
{% else %}
  <!-- Use config -->
{% endif %}
```

## Security Considerations

1. **Trusted Sources Only**: Only load YAML from trusted sources
2. **No Code Execution**: The parser doesn't execute arbitrary code
3. **Type Safety**: Be aware of automatic type conversion
4. **Size Limits**: Large YAML files may impact performance

## See Also

- [Data Sources Guide](./DataSources-Guide.md)
- [Data Filters Reference](./DataFilters-Reference.md)
- [YAML Specification](https://yaml.org/spec/1.2/spec.html)