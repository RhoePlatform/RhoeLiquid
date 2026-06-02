# Liquid for Handlebars/Mustache Users - QuickStart Guide

## Core Design Philosophy Comparison

### Fundamental Difference: Logic-less vs Logic-full
- **Handlebars/Mustache**: Logic-less templates - minimal logic in templates
- **Liquid**: Logic-full templates - complete programming constructs

### Similarities
- Both separate presentation from data
- Both support partials/includes
- Both have helper/filter systems
- Both auto-escape HTML by default

### Key Differences
- **Delimiters**: Handlebars uses `{{}}` and `{{#}}`, Liquid uses `{{}}` and `{% %}`
- **Logic**: Liquid has real if/else, loops, and assignment
- **Filters vs Helpers**: Different syntax and philosophy
- **Context**: Liquid has explicit variable scoping

## Syntax Translation Guide

### Basic Output

```handlebars
{{! Handlebars }}
{{name}}
{{user.name}}
{{user.address.city}}
{{{unescapedHTML}}}
```

```liquid
{% comment %} Liquid {% endcomment %}
{{ name }}
{{ user.name }}
{{ user.address.city }}
{{ unescapedHTML }}  {% comment %} Liquid auto-escapes by default {% endcomment %}
```

**Key difference**: Liquid doesn't need triple-braces for unescaped content in most contexts.

### Conditionals

```handlebars
{{! Handlebars - Limited logic }}
{{#if user.premium}}
  Premium member
{{else}}
  Regular member
{{/if}}

{{#unless loggedIn}}
  Please log in
{{/unless}}

{{! Implicit truthiness }}
{{#if items}}
  Has items
{{/if}}
```

```liquid
{% comment %} Liquid - Full conditionals {% endcomment %}
{% if user.premium %}
  Premium member
{% else %}
  Regular member
{% endif %}

{% unless loggedIn %}
  Please log in
{% endunless %}

{% comment %} Explicit comparisons available {% endcomment %}
{% if items.size > 0 %}
  Has items
{% endif %}

{% comment %} Complex conditions {% endcomment %}
{% if user.age >= 18 and user.country == 'US' %}
  Can vote in US
{% elsif user.age >= 16 and user.country == 'UK' %}
  Can vote in UK
{% endif %}
```

### Loops

```handlebars
{{! Handlebars }}
{{#each users}}
  <li>{{this.name}} - {{@index}}</li>
  {{#if @first}}First user!{{/if}}
  {{#if @last}}Last user!{{/if}}
{{/each}}

{{! With key-value }}
{{#each object}}
  {{@key}}: {{this}}
{{/each}}
```

```liquid
{% comment %} Liquid {% endcomment %}
{% for user in users %}
  <li>{{ user.name }} - {{ forloop.index0 }}</li>
  {% if forloop.first %}First user!{% endif %}
  {% if forloop.last %}Last user!{% endif %}
{% endfor %}

{% comment %} No direct object iteration - restructure data {% endcomment %}
{% for item in object_pairs %}
  {{ item.key }}: {{ item.value }}
{% endfor %}

{% comment %} Or use specific arrays {% endcomment %}
{% for key in object_keys %}
  {{ key }}: {{ object[key] }}
{% endfor %}
```

**Loop variable mapping:**

| Handlebars | Liquid |
|------------|--------|
| `@index` | `forloop.index0` |
| `@first` | `forloop.first` |
| `@last` | `forloop.last` |
| `@key` | (restructure data) |
| `this` | loop variable name |

### Helpers vs Filters

```handlebars
{{! Handlebars - Helpers with parentheses }}
{{uppercase name}}
{{formatDate date "YYYY-MM-DD"}}
{{add price tax}}
{{#if (equals status "active")}}...{{/if}}

{{! Custom helper }}
{{truncate description 100}}
```

```liquid
{% comment %} Liquid - Filters with pipes {% endcomment %}
{{ name | upcase }}
{{ date | date: "%Y-%m-%d" }}
{{ price | plus: tax }}
{% if status == "active" %}...{% endif %}

{% comment %} Chained filters {% endcomment %}
{{ description | truncate: 100 }}
{{ price | plus: tax | times: 1.1 | round: 2 }}
```

### Block Helpers vs Tags

```handlebars
{{! Handlebars - Block helpers }}
{{#with user}}
  <h1>{{name}}</h1>
  <p>{{email}}</p>
{{/with}}

{{#each users}}
  {{#with address}}
    {{street}}, {{city}}
  {{/with}}
{{/each}}

{{! Custom block helper }}
{{#markdown}}
  # This is markdown
  It gets converted to HTML
{{/markdown}}
```

```liquid
{% comment %} Liquid - No direct 'with' equivalent {% endcomment %}
<h1>{{ user.name }}</h1>
<p>{{ user.email }}</p>

{% for user in users %}
  {{ user.address.street }}, {{ user.address.city }}
{% endfor %}

{% comment %} Use capture for block processing {% endcomment %}
{% capture markdown_content %}
  # This is markdown
  It gets converted to HTML
{% endcapture %}
{{ markdown_content | markdownify }}  {% comment %} If filter available {% endcomment %}
```

### Partials vs Includes

```handlebars
{{! Handlebars }}
{{> header}}
{{> userCard user=currentUser}}

{{! With context }}
{{#each users}}
  {{> userRow}}
{{/each}}

{{! Block partials }}
{{#> layout}}
  {{#*inline "content"}}
    <h1>Page content</h1>
  {{/inline}}
{{/layout}}
```

```liquid
{% comment %} Liquid {% endcomment %}
{% include 'header' %}
{% include 'userCard' user: currentUser %}

{% comment %} Explicit parameter passing {% endcomment %}
{% for user in users %}
  {% include 'userRow' user: user %}
{% endfor %}

{% comment %} Use Jekyll-style layouts or compose {% endcomment %}
{% comment %} In page: {% endcomment %}
---
layout: default
---
<h1>Page content</h1>
```

### Variable Assignment (Liquid only!)

```handlebars
{{! Handlebars - NO variable assignment }}
{{! Must prepare all data before rendering }}
```

```liquid
{% comment %} Liquid - Full assignment support {% endcomment %}
{% assign username = user.name | downcase %}
{% assign total = 0 %}

{% for item in cart.items %}
  {% assign total = total | plus: item.price %}
{% endfor %}

{% capture full_address %}
  {{ address.street }}
  {{ address.city }}, {{ address.state }} {{ address.zip }}
{% endcapture %}
```

### Common Patterns Translation

#### Conditional Classes

```handlebars
{{! Handlebars }}
<div class="user {{#if premium}}premium{{/if}} {{#if active}}active{{/if}}">
  {{name}}
</div>
```

```liquid
{% comment %} Liquid {% endcomment %}
<div class="user {% if premium %}premium{% endif %} {% if active %}active{% endif %}">
  {{ name }}
</div>

{% comment %} Or with filters {% endcomment %}
{% assign classes = 'user' %}
{% if premium %}{% assign classes = classes | append: ' premium' %}{% endif %}
{% if active %}{% assign classes = classes | append: ' active' %}{% endif %}
<div class="{{ classes }}">{{ name }}</div>
```

#### Default Values

```handlebars
{{! Handlebars - Need helper }}
{{#if name}}{{name}}{{else}}Anonymous{{/if}}
{{! Or with helper: {{default name "Anonymous"}} }}
```

```liquid
{% comment %} Liquid - Built-in filter {% endcomment %}
{{ name | default: "Anonymous" }}
```

#### Array Manipulation

```handlebars
{{! Handlebars - Limited array operations }}
{{#each (slice items 0 5)}}
  {{this}}
{{/each}}
```

```liquid
{% comment %} Liquid - Rich array filters {% endcomment %}
{% for item in items limit: 5 %}
  {{ item }}
{% endfor %}

{% comment %} Or with filters {% endcomment %}
{{ items | first: 5 | join: ", " }}

{% comment %} Complex filtering {% endcomment %}
{% assign active_users = users | where: "status", "active" | sort: "name" %}
```

#### Switch Statements

```handlebars
{{! Handlebars - No switch, use if/else }}
{{#if (equals status "pending")}}
  <span class="pending">Pending</span>
{{else if (equals status "approved")}}
  <span class="approved">Approved</span>
{{else}}
  <span class="other">{{status}}</span>
{{/if}}
```

```liquid
{% comment %} Liquid - Native case/when {% endcomment %}
{% case status %}
  {% when 'pending' %}
    <span class="pending">Pending</span>
  {% when 'approved' %}
    <span class="approved">Approved</span>
  {% else %}
    <span class="other">{{ status }}</span>
{% endcase %}
```

## Key Conceptual Shifts

### 1. From Logic-less to Logic-full
Handlebars pushes logic to the data preparation layer. Liquid allows logic in templates:

```liquid
{% comment %} Calculate in template instead of pre-calculating {% endcomment %}
{% assign discount = 0 %}
{% if user.premium %}
  {% assign discount = 0.2 %}
{% elsif user.member_since < '2020-01-01' %}
  {% assign discount = 0.1 %}
{% endif %}

Price: ${{ price | times: 1 | minus: discount | round: 2 }}
```

### 2. From Helpers to Filters
Handlebars helpers are functions. Liquid filters are data transformations:

```liquid
{% comment %} Filters are chainable data pipelines {% endcomment %}
{{ users | where: "active", true | map: "email" | join: ", " }}

{% comment %} Not function calls {% endcomment %}
{{ formatDate(date, "YYYY-MM-DD") }}  ❌ Won't work
{{ date | date: "%Y-%m-%d" }}         ✓ Correct
```

### 3. Explicit Context Management
Handlebars has implicit context switching. Liquid is always explicit:

```liquid
{% comment %} Always use full paths {% endcomment %}
{% for user in users %}
  {{ user.name }}  {% comment %} Not {{name}} {% endcomment %}
  {% for order in user.orders %}
    {{ order.id }} - {{ user.name }}  {% comment %} Parent still accessible {% endcomment %}
  {% endfor %}
{% endfor %}
```

## Migration Checklist

When converting Handlebars templates to Liquid:

1. **Replace `{{#tag}}` with `{% tag %}`**
2. **Replace `{{/tag}}` with `{% endtag %}`**
3. **Convert helpers to filters with `|`**
4. **Replace `this` with explicit variable names**
5. **Convert `@index` to `forloop.index0`**
6. **Add explicit logic for complex conditions**
7. **Restructure object iteration**
8. **Convert partials to includes with parameters**
9. **Replace block helpers with tags or captures**
10. **Add variable assignments where needed**

## Common Gotchas

1. **No implicit context switching**
   ```liquid
   {% for user in users %}
     {{ name }}  ❌ Won't work
     {{ user.name }}  ✓ Explicit path
   {% endfor %}
   ```

2. **Empty arrays are truthy**
   ```liquid
   {% if items %}  ⚠️ True even if empty
   {% if items.size > 0 %}  ✓ Check size
   ```

3. **Includes need explicit parameters**
   ```liquid
   {% include 'partial' %}  ⚠️ No access to parent scope
   {% include 'partial' item: item %}  ✓ Pass needed data
   ```

4. **Filters aren't function calls**
   ```liquid
   {{ helper(arg1, arg2) }}  ❌ Handlebars style
   {{ value | filter: arg1, arg2 }}  ✓ Liquid style
   ```

## Quick Reference Card

```liquid
{% comment %} Output {% endcomment %}
{{ variable }}
{{ object.property }}
{{ array[0] }} or {{ array.first }}

{% comment %} Logic {% endcomment %}
{% if condition %}...{% elsif %}...{% else %}...{% endif %}
{% unless condition %}...{% endunless %}
{% case var %}{% when 'val' %}...{% else %}...{% endcase %}

{% comment %} Loops {% endcomment %}
{% for item in collection %}
  {{ forloop.index0 }}: {{ item }}
{% endfor %}

{% comment %} Assignment (NEW!) {% endcomment %}
{% assign name = value %}
{% capture name %}...{% endcapture %}

{% comment %} Filters instead of helpers {% endcomment %}
{{ string | upcase }}
{{ number | plus: 10 | times: 1.1 }}
{{ array | where: "active", true | size }}

{% comment %} Includes {% endcomment %}
{% include 'name' param: value %}
```

## Power Features in Liquid

Features you gain moving from Handlebars to Liquid:

1. **Variable manipulation**
   ```liquid
   {% assign total = 0 %}
   {% for item in items %}
     {% assign total = total | plus: item.price %}
   {% endfor %}
   ```

2. **Complex filtering**
   ```liquid
   {{ products | where: "category", "electronics" | where: "price", ">", 100 | sort: "rating" | reverse | first: 10 }}
   ```

3. **String building**
   ```liquid
   {% capture meta_description %}
     {{ product.name }} - {{ product.category | capitalize }}
     Only ${{ product.price }}!
   {% endcapture %}
   <meta name="description" content="{{ meta_description | strip | escape }}">
   ```

4. **Numeric operations**
   ```liquid
   {% assign tax = price | times: 0.08 %}
   {% assign shipping = 5 %}
   {% assign total = price | plus: tax | plus: shipping | round: 2 %}
   ```

Welcome to the more powerful world of Liquid templates!