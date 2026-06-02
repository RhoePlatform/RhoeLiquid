# GraphQL Data Source Guide

The GraphQL data source enables powerful API integration by executing GraphQL queries against remote endpoints. Perfect for headless CMS integration, modern APIs, and dynamic data fetching.

## Table of Contents

1. [Overview](#overview)
2. [Basic Usage](#basic-usage)
3. [Query Variables](#query-variables)
4. [Authentication](#authentication)
5. [Error Handling](#error-handling)
6. [GraphQL Filters](#graphql-filters)
7. [Common Patterns](#common-patterns)
8. [Performance](#performance)
9. [Best Practices](#best-practices)

## Overview

The GraphQL data source provides:
- **Query Execution**: Run GraphQL queries with variables
- **Mutation Support**: Execute mutations (with care)
- **Introspection**: Discover API schema
- **Error Handling**: Detailed GraphQL error reporting
- **Caching**: Smart caching based on queries
- **Headers**: Authentication and custom headers

Supported URL schemes:
- `http://`, `https://` - Standard HTTP endpoints
- `graphql://` - Automatically converted to `https://`

Supported file extensions:
- `.graphql`, `.gql` - For query files

## Basic Usage

### Simple Query

```liquid
{% data posts = load("https://api.example.com/graphql",
    query: "query { posts { id title content author { name } } }") %}

{% for post in posts.data.posts %}
  <article>
    <h2>{{ post.title }}</h2>
    <p>By {{ post.author.name }}</p>
    {{ post.content }}
  </article>
{% endfor %}
```

### Query from File

Create a `.graphql` file:

```graphql
# posts.graphql
query GetPosts($limit: Int = 10) {
  posts(first: $limit) {
    edges {
      node {
        id
        title
        content
        publishedAt
        author {
          name
          avatar
        }
        tags
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

```liquid
{% data result = load("https://api.example.com/graphql?query=./posts.graphql") %}

{% for edge in result.data.posts.edges %}
  {% assign post = edge.node %}
  <article>
    <h2>{{ post.title }}</h2>
    <p>Published: {{ post.publishedAt | date: "%B %d, %Y" }}</p>
    {{ post.content }}
  </article>
{% endfor %}
```

## Query Variables

### Basic Variables

```liquid
{% data user = load("https://api.example.com/graphql",
    query: "query GetUser($id: ID!) { user(id: $id) { name email posts { title } } }",
    variables: {"id": "123"}) %}

<h1>{{ user.data.user.name }}</h1>
<p>{{ user.data.user.email }}</p>

<h2>Posts</h2>
<ul>
  {% for post in user.data.user.posts %}
    <li>{{ post.title }}</li>
  {% endfor %}
</ul>
```

### Complex Variables

```liquid
{% capture query %}
query SearchProducts($category: String, $minPrice: Float, $maxPrice: Float, $limit: Int = 20) {
  products(
    where: {
      category: $category
      price: { gte: $minPrice, lte: $maxPrice }
    }
    first: $limit
  ) {
    id
    name
    price
    description
    images {
      url
      alt
    }
  }
}
{% endcapture %}

{% assign variables = '{"category": "electronics", "minPrice": 100, "maxPrice": 1000}' | parse_json %}

{% data products = load("https://shop.example.com/graphql",
    query: query,
    variables: variables) %}

<div class="products">
  {% for product in products.data.products %}
    <div class="product">
      <h3>{{ product.name }}</h3>
      <p>${{ product.price }}</p>
      {% if product.images.size > 0 %}
        <img src="{{ product.images[0].url }}" alt="{{ product.images[0].alt }}">
      {% endif %}
    </div>
  {% endfor %}
</div>
```

## Authentication

### Bearer Token

```liquid
{% data profile = load("https://api.example.com/graphql",
    headers: {"Authorization": "Bearer " ~ access_token},
    query: "query { me { id name email role } }") %}

{% if profile.data %}
  <p>Welcome, {{ profile.data.me.name }}!</p>
  <p>Role: {{ profile.data.me.role }}</p>
{% else %}
  <p>Please log in</p>
{% endif %}
```

### API Key

```liquid
{% data data = load("https://api.example.com/graphql",
    headers: {"X-API-Key": api_key},
    query: "query { products { id name } }") %}
```

### Multiple Headers

```liquid
{% data data = load("https://api.example.com/graphql",
    headers: {
      "Authorization": "Bearer " ~ token,
      "X-Client-Version": "2.0",
      "Accept-Language": "en-US"
    },
    query: query_string) %}
```

## Error Handling

GraphQL responses can contain both data and errors:

### Basic Error Handling

```liquid
{% data result = load("https://api.example.com/graphql",
    query: "query { user(id: $id) { name } }",
    variables: {"id": user_id}) %}

{% if result.errors %}
  <div class="errors">
    {% for error in result.errors %}
      <p class="error">{{ error.message }}</p>
      {% if error.path %}
        <p>Path: {{ error.path | join: " > " }}</p>
      {% endif %}
    {% endfor %}
  </div>
{% endif %}

{% if result.data %}
  <p>User: {{ result.data.user.name }}</p>
{% endif %}
```

### Using Error Filters

```liquid
{% data result = load("https://api.example.com/graphql", query: query) %}

{% if result | graphql_has_errors %}
  <div class="alert alert-danger">
    <h4>Errors occurred:</h4>
    {% assign errors = result | graphql_errors %}
    {% for error in errors %}
      <p>{{ error.message }}</p>
    {% endfor %}
  </div>
{% else %}
  {% assign data = result | graphql_data %}
  <!-- Use data -->
{% endif %}
```

## GraphQL Filters

### graphql_data

Extract the data field from a GraphQL response:

```liquid
{% data response = load(graphql_endpoint, query: query) %}
{% assign posts = response | graphql_data | get: "posts" %}

{% for post in posts %}
  {{ post.title }}
{% endfor %}
```

### graphql_errors

Extract errors from a GraphQL response:

```liquid
{% assign errors = response | graphql_errors %}
{% if errors.size > 0 %}
  <ul class="errors">
    {% for error in errors %}
      <li>{{ error.message }}</li>
    {% endfor %}
  </ul>
{% endif %}
```

### graphql_has_errors

Check if a response contains errors:

```liquid
{% if response | graphql_has_errors %}
  <p>The request failed. Please try again.</p>
{% else %}
  <!-- Process successful response -->
{% endif %}
```

## Common Patterns

### 1. Headless CMS Integration

```liquid
{% capture content_query %}
query GetPage($slug: String!) {
  page(where: { slug: $slug }) {
    title
    content
    seo {
      title
      description
      keywords
    }
    sections {
      __typename
      ... on HeroSection {
        heading
        subheading
        backgroundImage {
          url
        }
      }
      ... on TextSection {
        body
      }
      ... on GallerySection {
        images {
          url
          caption
        }
      }
    }
  }
}
{% endcapture %}

{% data page = load("https://cms.example.com/graphql",
    query: content_query,
    variables: {"slug": page.slug}) %}

<!DOCTYPE html>
<html>
<head>
  <title>{{ page.data.page.seo.title | default: page.data.page.title }}</title>
  <meta name="description" content="{{ page.data.page.seo.description }}">
</head>
<body>
  <h1>{{ page.data.page.title }}</h1>
  
  {% for section in page.data.page.sections %}
    {% case section.__typename %}
      {% when "HeroSection" %}
        <section class="hero" style="background-image: url('{{ section.backgroundImage.url }}')">
          <h2>{{ section.heading }}</h2>
          <p>{{ section.subheading }}</p>
        </section>
      
      {% when "TextSection" %}
        <section class="text">
          {{ section.body }}
        </section>
      
      {% when "GallerySection" %}
        <section class="gallery">
          {% for image in section.images %}
            <figure>
              <img src="{{ image.url }}" alt="{{ image.caption }}">
              <figcaption>{{ image.caption }}</figcaption>
            </figure>
          {% endfor %}
        </section>
    {% endcase %}
  {% endfor %}
</body>
</html>
```

### 2. E-commerce Product Listing

```liquid
{% capture products_query %}
query GetProducts(
  $category: String
  $minPrice: Float
  $maxPrice: Float
  $sort: ProductSortInput
  $first: Int = 20
  $after: String
) {
  products(
    where: {
      category: { eq: $category }
      price: { gte: $minPrice, lte: $maxPrice }
    }
    orderBy: $sort
    first: $first
    after: $after
  ) {
    edges {
      node {
        id
        name
        slug
        price
        compareAtPrice
        description
        images(first: 1) {
          url
          alt
        }
        variants {
          id
          name
          available
        }
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
    totalCount
  }
}
{% endcapture %}

{% assign variables = '{}' | parse_json %}
{% if request.category %}
  {% assign variables = variables | merge: {"category": request.category} %}
{% endif %}
{% if request.min_price %}
  {% assign variables = variables | merge: {"minPrice": request.min_price | times: 1.0} %}
{% endif %}
{% if request.max_price %}
  {% assign variables = variables | merge: {"maxPrice": request.max_price | times: 1.0} %}
{% endif %}
{% if request.sort %}
  {% assign variables = variables | merge: {"sort": {"field": request.sort, "direction": "ASC"}} %}
{% endif %}

{% data result = load("https://shop.example.com/graphql",
    query: products_query,
    variables: variables) %}

<div class="products-grid">
  {% for edge in result.data.products.edges %}
    {% assign product = edge.node %}
    <div class="product-card">
      {% if product.images.size > 0 %}
        <img src="{{ product.images[0].url }}" alt="{{ product.images[0].alt }}">
      {% endif %}
      
      <h3>{{ product.name }}</h3>
      
      <div class="price">
        {% if product.compareAtPrice > product.price %}
          <span class="original-price">${{ product.compareAtPrice }}</span>
        {% endif %}
        <span class="current-price">${{ product.price }}</span>
      </div>
      
      <a href="/products/{{ product.slug }}" class="btn">View Details</a>
    </div>
  {% endfor %}
</div>

{% if result.data.products.pageInfo.hasNextPage %}
  <button data-cursor="{{ result.data.products.pageInfo.endCursor }}">
    Load More
  </button>
{% endif %}

<p>Showing {{ result.data.products.edges.size }} of {{ result.data.products.totalCount }} products</p>
```

### 3. User Dashboard

```liquid
{% capture dashboard_query %}
query GetDashboard {
  me {
    id
    name
    email
    avatar
    stats {
      posts
      followers
      following
    }
    recentPosts(first: 5) {
      id
      title
      publishedAt
      views
      likes
    }
    notifications(unreadOnly: true) {
      id
      type
      message
      createdAt
      read
    }
  }
}
{% endcapture %}

{% data dashboard = load("https://api.example.com/graphql",
    headers: {"Authorization": "Bearer " ~ session.token},
    query: dashboard_query) %}

{% if dashboard.data %}
  <div class="dashboard">
    <div class="user-info">
      <img src="{{ dashboard.data.me.avatar }}" alt="{{ dashboard.data.me.name }}">
      <h1>{{ dashboard.data.me.name }}</h1>
      <p>{{ dashboard.data.me.email }}</p>
    </div>
    
    <div class="stats">
      <div class="stat">
        <span class="value">{{ dashboard.data.me.stats.posts }}</span>
        <span class="label">Posts</span>
      </div>
      <div class="stat">
        <span class="value">{{ dashboard.data.me.stats.followers }}</span>
        <span class="label">Followers</span>
      </div>
      <div class="stat">
        <span class="value">{{ dashboard.data.me.stats.following }}</span>
        <span class="label">Following</span>
      </div>
    </div>
    
    <div class="recent-posts">
      <h2>Recent Posts</h2>
      <table>
        {% for post in dashboard.data.me.recentPosts %}
          <tr>
            <td>{{ post.title }}</td>
            <td>{{ post.publishedAt | date: "%b %d" }}</td>
            <td>{{ post.views }} views</td>
            <td>{{ post.likes }} likes</td>
          </tr>
        {% endfor %}
      </table>
    </div>
    
    {% if dashboard.data.me.notifications.size > 0 %}
      <div class="notifications">
        <h2>Notifications</h2>
        {% for notification in dashboard.data.me.notifications %}
          <div class="notification {{ notification.type }}">
            {{ notification.message }}
            <time>{{ notification.createdAt | date: "%b %d at %I:%M %p" }}</time>
          </div>
        {% endfor %}
      </div>
    {% endif %}
  </div>
{% else %}
  <p>Please log in to view your dashboard.</p>
{% endif %}
```

### 4. Search Implementation

```liquid
{% capture search_query %}
query Search($query: String!, $type: SearchType) {
  search(query: $query, type: $type) {
    results {
      __typename
      ... on Article {
        id
        title
        excerpt
        url
        publishedAt
      }
      ... on Product {
        id
        name
        description
        price
        image
        url
      }
      ... on User {
        id
        name
        bio
        avatar
        url
      }
    }
    totalCount
    facets {
      type {
        value
        count
      }
    }
  }
}
{% endcapture %}

{% if request.q %}
  {% assign variables = {"query": request.q} %}
  {% if request.type %}
    {% assign variables = variables | merge: {"type": request.type} %}
  {% endif %}
  
  {% data results = load("https://api.example.com/graphql",
      query: search_query,
      variables: variables) %}
  
  <h1>Search Results for "{{ request.q }}"</h1>
  
  {% if results.data.search.totalCount > 0 %}
    <p>Found {{ results.data.search.totalCount }} results</p>
    
    <!-- Facets -->
    <div class="facets">
      <h3>Filter by type:</h3>
      {% for facet in results.data.search.facets.type %}
        <a href="?q={{ request.q | url_encode }}&type={{ facet.value }}">
          {{ facet.value }} ({{ facet.count }})
        </a>
      {% endfor %}
    </div>
    
    <!-- Results -->
    <div class="search-results">
      {% for result in results.data.search.results %}
        {% case result.__typename %}
          {% when "Article" %}
            <article class="result-article">
              <h2><a href="{{ result.url }}">{{ result.title }}</a></h2>
              <p>{{ result.excerpt }}</p>
              <time>{{ result.publishedAt | date: "%B %d, %Y" }}</time>
            </article>
          
          {% when "Product" %}
            <div class="result-product">
              <img src="{{ result.image }}" alt="{{ result.name }}">
              <h3><a href="{{ result.url }}">{{ result.name }}</a></h3>
              <p>{{ result.description | truncate: 150 }}</p>
              <span class="price">${{ result.price }}</span>
            </div>
          
          {% when "User" %}
            <div class="result-user">
              <img src="{{ result.avatar }}" alt="{{ result.name }}">
              <h3><a href="{{ result.url }}">{{ result.name }}</a></h3>
              <p>{{ result.bio }}</p>
            </div>
        {% endcase %}
      {% endfor %}
    </div>
  {% else %}
    <p>No results found.</p>
  {% endif %}
{% endif %}
```

## Performance

### Caching Queries

```liquid
<!-- Cache for 1 hour -->
{% data posts = load("https://api.example.com/graphql",
    query: "query { posts { id title } }",
    cache: 3600) %}
```

### Query Optimization

1. **Request Only Needed Fields**:
```graphql
# Good - specific fields
query {
  user(id: "123") {
    name
    email
  }
}

# Avoid - unnecessary data
query {
  user(id: "123") {
    id
    name
    email
    bio
    avatar
    posts {
      id
      title
      content
      # ... many more fields
    }
  }
}
```

2. **Use Fragments for Reusability**:
```liquid
{% capture user_fragment %}
fragment UserBasic on User {
  id
  name
  avatar
}
{% endcapture %}

{% capture query %}
{{ user_fragment }}

query GetPost($id: ID!) {
  post(id: $id) {
    title
    content
    author {
      ...UserBasic
    }
    comments {
      text
      author {
        ...UserBasic
      }
    }
  }
}
{% endcapture %}
```

3. **Implement Pagination**:
```liquid
{% capture paginated_query %}
query GetPosts($first: Int = 10, $after: String) {
  posts(first: $first, after: $after) {
    edges {
      node {
        id
        title
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
{% endcapture %}
```

## Best Practices

### 1. Error Handling

Always check for errors:

```liquid
{% data result = load(endpoint, query: query) %}

{% if result.errors %}
  <!-- Handle errors -->
  {% for error in result.errors %}
    <p class="error">{{ error.message }}</p>
  {% endfor %}
{% endif %}

{% if result.data %}
  <!-- Process data -->
{% endif %}
```

### 2. Query Organization

Store complex queries in variables or files:

```liquid
<!-- In a separate file or capture -->
{% capture get_user_query %}
query GetUser($id: ID!) {
  user(id: $id) {
    name
    email
    profile {
      bio
      website
    }
  }
}
{% endcapture %}

<!-- Use the query -->
{% data user = load(endpoint, query: get_user_query, variables: {"id": "123"}) %}
```

### 3. Type Safety

Check for null values:

```liquid
{% if result.data.user %}
  <h1>{{ result.data.user.name }}</h1>
  
  {% if result.data.user.profile %}
    <p>{{ result.data.user.profile.bio }}</p>
  {% endif %}
{% else %}
  <p>User not found</p>
{% endif %}
```

### 4. Security

- Never expose sensitive tokens in templates
- Use environment variables for API keys
- Validate user input before using in queries
- Use parameterized queries, not string concatenation

### 5. Performance

- Cache stable queries
- Request only needed fields
- Implement proper pagination
- Use fragments for repeated selections
- Consider query complexity and depth

## Introspection

Discover API schema:

```liquid
{% data schema = load("https://api.example.com/graphql",
    query: "{ __schema { types { name kind description } } }") %}

<h2>Available Types</h2>
<ul>
  {% for type in schema.data.__schema.types %}
    {% unless type.name contains "__" %}
      <li>
        <strong>{{ type.name }}</strong> ({{ type.kind }})
        {% if type.description %}
          - {{ type.description }}
        {% endif %}
      </li>
    {% endunless %}
  {% endfor %}
</ul>
```

## Limitations

1. **Read-Only**: Mutations should be used carefully
2. **Complexity**: Very complex queries may timeout
3. **Rate Limiting**: Respect API rate limits
4. **Size Limits**: Large responses may be truncated

## See Also

- [Data Sources Guide](./DataSources-Guide.md)
- [Data Filters Reference](./DataFilters-Reference.md)
- [GraphQL Specification](https://spec.graphql.org/)