# XML/HTML Data Source Guide

The XML/HTML data source in RhoeLiquid provides powerful capabilities for loading, parsing, and querying structured markup documents. This guide covers everything you need to work with XML and HTML data effectively.

## Table of Contents

1. [Overview](#overview)
2. [Loading XML/HTML](#loading-xmlhtml)
3. [Data Structure](#data-structure)
4. [CSS Selectors](#css-selectors)
5. [XPath Queries](#xpath-queries)
6. [Filters Reference](#filters-reference)
7. [Common Patterns](#common-patterns)
8. [Web Scraping](#web-scraping)
9. [RSS/Atom Feeds](#rssatom-feeds)
10. [Performance Tips](#performance-tips)

## Overview

The XML/HTML data source supports:
- **XML**: Standard XML with namespace support
- **HTML**: HTML5 with lenient parsing (handles malformed HTML)
- **XHTML**: Strict XML-compliant HTML
- **RSS/Atom**: Feed formats as structured data
- **SVG**: Scalable Vector Graphics

Key features:
- Intelligent format detection
- CSS selector support for HTML
- XPath queries for XML
- Namespace-aware processing
- Mixed content handling
- Lenient HTML parsing

## Loading XML/HTML

### Basic Loading

```liquid
<!-- Load local HTML file -->
{% data page = load("./index.html") %}

<!-- Load XML file -->
{% data books = load("./catalog.xml") %}

<!-- Load from URL -->
{% data weather = load("https://api.weather.com/data.xml") %}
```

### With Options

```liquid
<!-- Load with caching -->
{% data feed = load("https://blog.example.com/rss.xml", cache: 3600) %}

<!-- Load with headers -->
{% data api = load("https://api.example.com/data.xml",
                  headers: {"API-Key": "secret"},
                  timeout: 10) %}
```

## Data Structure

XML/HTML is converted to a unified DataValue structure:

### Element Structure

Each element becomes an object with:
- `@name`: Element tag name
- `@attributes`: Object containing attributes
- `@text`: Direct text content (if any)
- `@full_text`: All text including nested elements
- Child elements as properties

### Example XML

```xml
<book id="123" category="fiction">
  <title>The Great Gatsby</title>
  <author>F. Scott Fitzgerald</author>
  <price currency="USD">12.99</price>
</book>
```

Becomes:

```json
{
  "@name": "book",
  "@attributes": {
    "id": "123",
    "category": "fiction"
  },
  "title": "The Great Gatsby",
  "author": "F. Scott Fitzgerald",
  "price": {
    "@name": "price",
    "@attributes": {
      "currency": "USD"
    },
    "@text": "12.99"
  }
}
```

### HTML Example

```html
<div class="product" data-id="456">
  <h2>Product Name</h2>
  <p class="price">$29.99</p>
  <button onclick="buy()">Buy Now</button>
</div>
```

Becomes accessible as:

```liquid
{{ element["@attributes"]["class"] }}     <!-- "product" -->
{{ element["@attributes"]["data-id"] }}   <!-- "456" -->
{{ element.h2 }}                          <!-- "Product Name" -->
{{ element.p["@text"] }}                  <!-- "$29.99" -->
```

## CSS Selectors

Use CSS selectors to query HTML documents:

The active selector surface supports the common patterns shown below: element selectors, IDs, classes, compound selectors such as `a.btn.btn-primary`, attribute selectors, descendant selectors, and direct-child selectors.

### Basic Selectors

```liquid
<!-- Select by tag -->
{{ html | select: "h1" }}

<!-- Select by ID -->
{{ html | select: "#main-content" }}

<!-- Select by class -->
{{ html | select: ".product" }}

<!-- Select all matching -->
{% assign products = html | select_all: ".product-item" %}
```

### Advanced Selectors

```liquid
<!-- Descendant selector -->
{{ html | select: "div.content p" }}

<!-- Direct child -->
{{ html | select: "ul > li" }}

<!-- Attribute selector -->
{{ html | select: "a[target='_blank']" }}
{{ html | select: "input[type='email']" }}

<!-- Multiple classes -->
{{ html | select: ".btn.btn-primary" }}
```

### Working with Results

```liquid
{% data page = load("./page.html") %}

<!-- Get first match -->
{% assign header = page | select: "h1" %}
{{ header | text }}

<!-- Get all matches -->
{% assign links = page | select_all: "a" %}
{% for link in links %}
  {{ link | attr: "href" }} - {{ link | text }}
{% endfor %}
```

## XPath Queries

RhoeLiquid ships a practical XPath subset for common XML querying patterns.

The actively supported subset includes:
- absolute and descendant element paths such as `/catalog/book/title` and `//book`
- attribute predicates such as `//book[@category='fiction']`
- child-value predicates such as `//book[price>10]`
- text predicates such as `//title[contains(text(),'Guide')]`
- common position filters such as `[1]`, `[last()]`, and `[position()>2]`
- attribute projection such as `//@id` and `//book/@category`

This is enough for the examples below, but it is intentionally narrower than a full XPath 1.0 engine.

### Basic XPath

```liquid
<!-- Select all elements -->
{{ xml | xpath: "//book" }}

<!-- Select by path -->
{{ xml | xpath: "/catalog/book/title" }}

<!-- Select with predicate -->
{{ xml | xpath: "//book[@category='fiction']" }}
{{ xml | xpath: "//book[price>10]" }}
```

### Advanced XPath

```liquid
<!-- Position-based selection -->
{{ xml | xpath: "//book[1]" }}              <!-- First book -->
{{ xml | xpath: "//book[last()]" }}         <!-- Last book -->
{{ xml | xpath: "//book[position()>2]" }}   <!-- After second -->

<!-- Text content -->
{{ xml | xpath: "//title[contains(text(),'Guide')]" }}

<!-- Attributes -->
{{ xml | xpath: "//@id" }}                  <!-- All id attributes -->
{{ xml | xpath: "//book/@category" }}       <!-- Category attributes -->
```

## Filters Reference

### select / select_all

Query elements using CSS selectors:

```liquid
<!-- Single element -->
{{ html | select: ".main-content" }}

<!-- Multiple elements -->
{% assign items = html | select_all: "li.menu-item" %}
```

### xpath

Query using XPath expressions:

```liquid
{{ xml | xpath: "//person[@age>18]" }}
```

Programmatic code can use the same shared query engine directly on `DataValue`:

```swift
let document = try await XMLDataSource().load(from: fileURL, options: LoadOptions())
let header = document.select("h1")
let products = document.selectAll(".product-item")
let titles = document.xpath("//book/title")
```

### text

Extract text content:

```liquid
<!-- Simple text -->
{{ element | text }}

<!-- From selection -->
{{ html | select: "h1" | text }}
```

### attr

Get attribute values:

```liquid
{{ element | attr: "href" }}
{{ element | attr: "class" }}
{{ element | attr: "data-value" }}
```

### inner_html

Get inner HTML content:

```liquid
{{ element | inner_html }}
```

### strip_html

Remove all HTML tags:

```liquid
{{ content | strip_html }}
{{ post.content | strip_html | truncate: 200 }}
```

### tag_name

Get element tag name:

```liquid
{{ element | tag_name }}  <!-- "div", "p", etc. -->
```

### children

Get child elements:

```liquid
<!-- All children -->
{% assign items = element | children %}

<!-- Specific tag children -->
{% assign paragraphs = element | children: "p" %}
```

## Common Patterns

### Navigation Menu

```liquid
{% data nav = load("./navigation.html") %}
{% assign menu_items = nav | select_all: "nav li" %}

<ul class="menu">
{% for item in menu_items %}
  <li>
    {% assign link = item | select: "a" %}
    <a href="{{ link | attr: 'href' }}">
      {{ link | text }}
    </a>
  </li>
{% endfor %}
</ul>
```

### Product Listing

```liquid
{% data products = load("./products.html") %}
{% assign items = products | select_all: ".product" %}

<div class="products">
{% for product in items %}
  <div class="product-card">
    <h3>{{ product | select: ".title" | text }}</h3>
    <p class="price">{{ product | select: ".price" | text }}</p>
    <p>{{ product | select: ".description" | text }}</p>
    <a href="{{ product | select: "a.details" | attr: 'href' }}">
      View Details
    </a>
  </div>
{% endfor %}
</div>
```

### Table Parsing

```liquid
{% data table = load("./data-table.html") %}
{% assign rows = table | select_all: "table tr" %}

{% for row in rows | offset: 1 %}  <!-- Skip header -->
  {% assign cells = row | children: "td" %}
  Name: {{ cells[0] | text }}
  Value: {{ cells[1] | text }}
  Status: {{ cells[2] | text }}
{% endfor %}
```

## Web Scraping

### Basic Scraping

```liquid
{% data page = load("https://example.com/products") %}
{% assign products = page | select_all: ".product-listing" %}

{% for product in products %}
  {% assign name = product | select: "h2" | text %}
  {% assign price = product | select: ".price" | text %}
  {% assign image = product | select: "img" | attr: "src" %}
  
  {{ name }} - {{ price }}
{% endfor %}
```

### Advanced Scraping

```liquid
{% data results = load("https://search.example.com/results",
                      headers: {"User-Agent": "RhoeLiquid/1.0"}) %}

<!-- Extract pagination -->
{% assign pages = results | select_all: ".pagination a" %}
{% assign next_url = results | select: "a.next" | attr: "href" %}

<!-- Extract data -->
{% assign items = results | select_all: "article.result" %}
{% for item in items %}
  {% assign title = item | select: "h3" | text %}
  {% assign excerpt = item | select: ".excerpt" | text | strip_html %}
  {% assign meta = item | select_all: ".meta span" %}
  
  <article>
    <h3>{{ title }}</h3>
    <p>{{ excerpt }}</p>
    <div class="meta">
      Date: {{ meta[0] | text }}
      Author: {{ meta[1] | text }}
    </div>
  </article>
{% endfor %}
```

## RSS/Atom Feeds

### RSS Feed Processing

```liquid
{% data feed = load("https://blog.example.com/rss.xml") %}
{% assign channel = feed.rss.channel %}

<h1>{{ channel.title }}</h1>
<p>{{ channel.description }}</p>

{% for item in channel.item | limit: 10 %}
  <article>
    <h2><a href="{{ item.link }}">{{ item.title }}</a></h2>
    <time>{{ item.pubDate | date: "%B %d, %Y" }}</time>
    {{ item.description | strip_html | truncate: 200 }}
  </article>
{% endfor %}
```

### Atom Feed Processing

```liquid
{% data atom = load("https://blog.example.com/atom.xml") %}
{% assign entries = atom.feed.entry %}

<h1>{{ atom.feed.title }}</h1>

{% for entry in entries | limit: 10 %}
  <article>
    <h2><a href="{{ entry.link['@attributes'].href }}">
      {{ entry.title }}
    </a></h2>
    <time>{{ entry.updated | date: "%B %d, %Y" }}</time>
    {{ entry.content | strip_html | truncate: 200 }}
  </article>
{% endfor %}
```

## Performance Tips

### 1. Cache External URLs

```liquid
<!-- Cache for 1 hour -->
{% data page = load("https://example.com/data.xml", cache: 3600) %}
```

### 2. Use Specific Selectors

```liquid
<!-- Good: Specific selector -->
{{ html | select: "#content .product-list .item" }}

<!-- Less efficient: Generic selector -->
{{ html | select: ".item" }}
```

### 3. Limit Results Early

```liquid
<!-- Process only what you need -->
{% assign top_items = xml | xpath: "//item[position()<=10]" %}
```

### 4. Extract Once, Use Multiple Times

```liquid
{% data page = load("./page.html") %}
{% assign content = page | select: "#main-content" %}

<!-- Reuse extracted content -->
{{ content | select: "h1" | text }}
{{ content | select_all: "p" | size }} paragraphs
```

### 5. Handle Large Documents

For very large XML/HTML files:

```liquid
<!-- Load with size limit -->
{% data doc = load("./large.xml", max_size: 5242880) %} <!-- 5MB -->

<!-- Process in chunks if possible -->
{% assign sections = doc | xpath: "//section" %}
{% for section in sections %}
  <!-- Process each section individually -->
{% endfor %}
```

## Error Handling

### Invalid Markup

```liquid
{% data page = load("./page.html") %}
{% if page %}
  <!-- Successfully loaded and parsed -->
  {{ page | select: "title" | text }}
{% else %}
  <!-- Failed to parse -->
  <p>Error loading page</p>
{% endif %}
```

### Missing Elements

```liquid
{% assign header = page | select: "h1" %}
{% if header %}
  {{ header | text }}
{% else %}
  <h1>Default Title</h1>
{% endif %}
```

### Safe Attribute Access

```liquid
<!-- Safe with default -->
{% assign url = link | attr: "href" | default: "#" %}

<!-- Check existence -->
{% if element | attr: "data-id" %}
  ID: {{ element | attr: "data-id" }}
{% endif %}
```

## Examples

### Complete Web Page Parser

```liquid
{% data page = load("https://news.example.com") %}

<!-- Extract metadata -->
{% assign title = page | select: "title" | text %}
{% assign description = page | select: "meta[name='description']" | attr: "content" %}

<!-- Extract navigation -->
{% assign nav_items = page | select_all: "nav a" %}

<!-- Extract main content -->
{% assign articles = page | select_all: "article.news-item" %}

<div class="parsed-content">
  <header>
    <h1>{{ title }}</h1>
    <p>{{ description }}</p>
  </header>
  
  <nav>
    {% for item in nav_items %}
      <a href="{{ item | attr: 'href' }}">{{ item | text }}</a>
    {% endfor %}
  </nav>
  
  <main>
    {% for article in articles %}
      <article>
        <h2>{{ article | select: "h2" | text }}</h2>
        <time>{{ article | select: "time" | text }}</time>
        {{ article | select: ".content" | inner_html }}
      </article>
    {% endfor %}
  </main>
</div>
```

### API Response Processing

```liquid
{% data response = load("https://api.example.com/users.xml",
                       headers: {"Accept": "application/xml",
                               "API-Key": env.API_KEY}) %}

{% assign users = response | xpath: "//user" %}

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Email</th>
      <th>Role</th>
    </tr>
  </thead>
  <tbody>
    {% for user in users %}
    <tr>
      <td>{{ user.name }}</td>
      <td>{{ user.email }}</td>
      <td>{{ user.role }}</td>
    </tr>
    {% endfor %}
  </tbody>
</table>
```

## Conclusion

The XML/HTML data source provides powerful tools for working with structured markup in RhoeLiquid templates. Whether you're building a static site generator, web scraper, or API client, these features enable sophisticated document processing with clean, maintainable template code.

For more information, see:
- [Data Sources Guide](./DataSources-Guide.md)
- [Data Filters Reference](./DataFilters-Reference.md)
- [API Reference](./API-Reference.md)
