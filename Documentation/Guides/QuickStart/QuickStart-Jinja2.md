# Liquid for Jinja2 Users - QuickStart Guide

## Core Design Philosophy Comparison

### Similarities
- **Delimiter syntax**: Both use `{{ }}` for output and `{% %}` for logic
- **Filters**: Both support piped filters with `|`
- **Template inheritance**: Both have include/partial systems
- **Control flow**: Both have if/else, for loops, and variable assignment

### Key Differences
- **Whitespace control**: Jinja2 uses `{%- -%}`, Liquid doesn't
- **Python vs Ruby heritage**: Jinja2 is Pythonic, Liquid is Ruby-inspired
- **Macro system**: Jinja2 macros map cleanly to `rhoeExtended` macros; strict `shopifyCompatible` mode still prefers includes with parameters
- **Template inheritance**: Jinja2 has blocks/extends, Liquid uses layouts differently

## Syntax Translation Guide

### Variables and Output

```jinja2
{# Jinja2 #}
{{ user.name }}
{{ users[0] }}
{{ users.0 }}  {# Alternative syntax #}
{{ name|default('Anonymous') }}
```

```liquid
{% comment %} Liquid {% endcomment %}
{{ user.name }}
{{ users[0] }}
{{ users.first }}  {% comment %} Liquid convenience {% endcomment %}
{{ name | default: 'Anonymous' }}
```

**Key differences:**
- Liquid filters use `:` for arguments, not parentheses
- Liquid has convenience accessors like `.first`, `.last`, `.size`

### Filters

```jinja2
{# Jinja2 - Python-style function calls #}
{{ name|upper }}
{{ price|round(2) }}
{{ items|join(', ') }}
{{ text|truncate(50, true, '...') }}
{{ users|selectattr('active')|list }}
```

```liquid
{% comment %} Liquid - Ruby-style with colons {% endcomment %}
{{ name | upcase }}
{{ price | round: 2 }}
{{ items | join: ', ' }}
{{ text | truncate: 50, '...' }}
{{ users | where: 'active', true }}
```

**Filter comparison table:**

| Jinja2 | Liquid | Notes |
|--------|--------|-------|
| `upper` | `upcase` | |
| `lower` | `downcase` | |
| `capitalize` | `capitalize` | |
| `trim` | `strip` | |
| `length` | `size` | |
| `first` | `first` | |
| `last` | `last` | |
| `round(n)` | `round: n` | |
| `default(value)` | `default: value` | |
| `escape` | `escape` | |
| `safe` | (automatic) | Liquid auto-escapes |
| `selectattr` | `where` | Different syntax |
| `rejectattr` | `where` + `unless` | Combine tags |
| `map` | `map` | |
| `sum` | (custom filter) | Not built-in |
| `groupby` | `group_by` | |

### Control Flow

#### If Statements

```jinja2
{# Jinja2 #}
{% if user.premium %}
    Premium user
{% elif user.registered %}
    Registered user
{% else %}
    Guest
{% endif %}

{% if name is defined %}
    Hello {{ name }}
{% endif %}

{% if items %}  {# Truthy check #}
    Has items
{% endif %}
```

```liquid
{% comment %} Liquid {% endcomment %}
{% if user.premium %}
    Premium user
{% elsif user.registered %}
    Registered user
{% else %}
    Guest
{% endif %}

{% if name %}  {% comment %} nil/null is falsy {% endcomment %}
    Hello {{ name }}
{% endif %}

{% if items.size > 0 %}  {% comment %} Explicit size check {% endcomment %}
    Has items
{% endif %}
```

**Key differences:**
- `elif` → `elsif`
- No `is defined` test (use truthiness)
- Empty arrays are truthy in Liquid (check `.size`)

#### Loops

```jinja2
{# Jinja2 #}
{% for user in users %}
    {{ loop.index }}: {{ user.name }}
    {% if loop.first %}First!{% endif %}
    {% if loop.last %}Last!{% endif %}
{% else %}
    No users found
{% endfor %}

{% for key, value in dict.items() %}
    {{ key }}: {{ value }}
{% endfor %}

{% for i in range(5) %}
    {{ i }}
{% endfor %}
```

```liquid
{% comment %} Liquid {% endcomment %}
{% for user in users %}
    {{ forloop.index }}: {{ user.name }}
    {% if forloop.first %}First!{% endif %}
    {% if forloop.last %}Last!{% endif %}
{% else %}
    No users found
{% endfor %}

{% comment %} No dict iteration - restructure data {% endcomment %}
{% for item in dict_items %}
    {{ item.key }}: {{ item.value }}
{% endfor %}

{% for i in (1..5) %}
    {{ i }}
{% endfor %}
```

**Loop variable mapping:**

| Jinja2 | Liquid |
|--------|--------|
| `loop.index` | `forloop.index` |
| `loop.index0` | `forloop.index0` |
| `loop.first` | `forloop.first` |
| `loop.last` | `forloop.last` |
| `loop.length` | `forloop.length` |
| `loop.revindex` | `forloop.rindex` |
| `loop.revindex0` | `forloop.rindex0` |
| `loop.cycle()` | `{% cycle %}` tag |

### Variable Assignment

```jinja2
{# Jinja2 #}
{% set name = 'John' %}
{% set total = price * quantity %}
{% set users = users|selectattr('active') %}

{# Namespace object #}
{% set ns = namespace(total=0) %}
{% for item in items %}
    {% set ns.total = ns.total + item.price %}
{% endfor %}
```

```liquid
{% comment %} Liquid {% endcomment %}
{% assign name = 'John' %}
{% assign total = price | times: quantity %}
{% assign users = users | where: 'active', true %}

{% comment %} Direct accumulation {% endcomment %}
{% assign total = 0 %}
{% for item in items %}
    {% assign total = total | plus: item.price %}
{% endfor %}
```

### Macros vs Includes

```jinja2
{# Jinja2 - Macro definition #}
{% macro user_card(user, show_email=false) %}
<div class="user-card">
    <h3>{{ user.name }}</h3>
    {% if show_email %}
        <p>{{ user.email }}</p>
    {% endif %}
</div>
{% endmacro %}

{# Usage #}
{{ user_card(user, show_email=true) }}
```

```liquid
{% comment %} Liquid - Include file: _user_card.liquid {% endcomment %}
<div class="user-card">
    <h3>{{ include.user.name }}</h3>
    {% if include.show_email %}
        <p>{{ include.user.email }}</p>
    {% endif %}
</div>

{% comment %} Usage {% endcomment %}
{% include 'user_card' user: user, show_email: true %}
```

### Template Inheritance

```jinja2
{# Jinja2 - base.html #}
<!DOCTYPE html>
<html>
<head>
    <title>{% block title %}Default{% endblock %}</title>
</head>
<body>
    {% block content %}{% endblock %}
</body>
</html>

{# child.html #}
{% extends "base.html" %}
{% block title %}{{ page_title }}{% endblock %}
{% block content %}
    <h1>Welcome!</h1>
{% endblock %}
```

```liquid
{% comment %} Liquid - Use Jekyll-style layouts or compose with includes {% endcomment %}
{% comment %} _layouts/base.liquid {% endcomment %}
<!DOCTYPE html>
<html>
<head>
    <title>{{ page.title | default: 'Default' }}</title>
</head>
<body>
    {{ content }}
</body>
</html>

{% comment %} page.liquid {% endcomment %}
---
layout: base
title: My Page
---
<h1>Welcome!</h1>
```

### Whitespace Control

```jinja2
{# Jinja2 #}
{%- if true -%}
    No surrounding whitespace
{%- endif -%}

{{ name|trim }}
```

```liquid
{% comment %} Liquid - Use capture to control whitespace {% endcomment %}
{% capture output %}
    {% if true %}
        Content with whitespace
    {% endif %}
{% endcapture %}
{{ output | strip }}
```

### Common Patterns

#### Pagination

```jinja2
{# Jinja2 #}
{% for page in range(1, total_pages + 1) %}
    {% if page == current_page %}
        <strong>{{ page }}</strong>
    {% else %}
        <a href="?page={{ page }}">{{ page }}</a>
    {% endif %}
{% endfor %}
```

```liquid
{% comment %} Liquid {% endcomment %}
{% for page in (1..total_pages) %}
    {% if page == current_page %}
        <strong>{{ page }}</strong>
    {% else %}
        <a href="?page={{ page }}">{{ page }}</a>
    {% endif %}
{% endfor %}
```

#### Working with Dates

```jinja2
{# Jinja2 #}
{{ post.date|date('%Y-%m-%d') }}
{{ now|date('%B %d, %Y') }}
```

```liquid
{% comment %} Liquid {% endcomment %}
{{ post.date | date: '%Y-%m-%d' }}
{{ 'now' | date: '%B %d, %Y' }}
```

#### Nested Data Access

```jinja2
{# Jinja2 #}
{{ config.get('features', {}).get('enabled', []) }}
{{ user.profile.settings.theme|default('light') }}
```

```liquid
{% comment %} Liquid - More explicit {% endcomment %}
{{ config.features.enabled }}
{{ user.profile.settings.theme | default: 'light' }}
```

## Migration Checklist

When converting Jinja2 templates to Liquid:

1. **Replace `elif` with `elsif`**
2. **Convert filter arguments from `()` to `:`**
3. **Change `loop.*` to `forloop.*`**
4. **Replace `set` with `assign`**
5. **Convert macros to `rhoeExtended` `{% macro %}` / `{% call %}` blocks, or to include files if you need strict `shopifyCompatible` mode**
6. **Handle empty array checks explicitly with `.size`**
7. **Remove whitespace control (`{%-` and `-%}`)**
8. **Update filter names (see table above)**
9. **Restructure dict iteration**
10. **Replace `is defined` checks with simple truthiness**

## Common Gotchas

1. **Empty arrays are truthy** in Liquid (unlike Python)
   ```liquid
   {% if items %}  ⚠️ Always true, even if empty
   {% if items.size > 0 %}  ✓ Correct check
   ```

2. **No arbitrary expressions** in conditions
   ```liquid
   {% if a + b > c %}  ❌ Won't work
   {% assign sum = a | plus: b %}
   {% if sum > c %}  ✓ Works
   ```

3. **Filters can't be chained with logic**
   ```liquid
   {{ name | upcase or 'DEFAULT' }}  ❌
   {{ name | default: 'anonymous' | upcase }}  ✓
   ```

4. **No list comprehensions or generators**
   - Use `map`, `where`, and other filters instead

5. **Include files need explicit parameters**
   - Parent scope isn't automatically available

## Quick Reference Card

```liquid
{% comment %} Variables {% endcomment %}
{{ variable }}
{{ hash.key }}
{{ array[0] }} or {{ array.first }}

{% comment %} Filters {% endcomment %}
{{ 'hello' | upcase }}
{{ price | plus: tax | round: 2 }}

{% comment %} Control Flow {% endcomment %}
{% if condition %}...{% elsif %}...{% else %}...{% endif %}
{% unless condition %}...{% endunless %}
{% case variable %}{% when 'value' %}...{% endcase %}

{% comment %} Loops {% endcomment %}
{% for item in collection %}
  {{ forloop.index }}: {{ item }}
{% endfor %}

{% comment %} Assignment {% endcomment %}
{% assign variable = value %}
{% capture variable %}...{% endcapture %}

{% comment %} Includes {% endcomment %}
{% include 'partial' param1: value1, param2: value2 %}
```

Now you're ready to write Liquid templates with your Jinja2 knowledge!
