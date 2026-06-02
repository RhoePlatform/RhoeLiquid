# Template Inheritance Guide

Template inheritance is one of the most powerful features of RhoeLiquid, allowing you to build flexible, maintainable template hierarchies.

## Overview

Template inheritance enables you to:
- Define a base "skeleton" template with common elements
- Create child templates that override specific blocks
- Build multi-level inheritance hierarchies
- Maintain DRY (Don't Repeat Yourself) principles

## Basic Syntax

### Extends Tag

The `{% extends %}` tag specifies which template to inherit from:

```liquid
{% extends "base.liquid" %}
```

**Important**: The `extends` tag must be the first tag in the template.

### Block Tags

Blocks define areas that child templates can override:

```liquid
{% block content %}
    Default content here
{% endblock %}
```

## Simple Example

### Base Template (base.liquid)

```liquid
<!DOCTYPE html>
<html>
<head>
    <title>{% block title %}My Site{% endblock %}</title>
</head>
<body>
    <header>
        {% block header %}
        <h1>Welcome</h1>
        {% endblock %}
    </header>
    
    <main>
        {% block content %}
        <p>Default content</p>
        {% endblock %}
    </main>
    
    <footer>
        {% block footer %}
        <p>&copy; 2024</p>
        {% endblock %}
    </footer>
</body>
</html>
```

### Child Template (page.liquid)

```liquid
{% extends "base.liquid" %}

{% block title %}About Us{% endblock %}

{% block content %}
<h2>About Our Company</h2>
<p>We are a leading provider of amazing products.</p>
{% endblock %}
```

### Result

```html
<!DOCTYPE html>
<html>
<head>
    <title>About Us</title>
</head>
<body>
    <header>
        <h1>Welcome</h1>
    </header>
    
    <main>
        <h2>About Our Company</h2>
        <p>We are a leading provider of amazing products.</p>
    </main>
    
    <footer>
        <p>&copy; 2024</p>
    </footer>
</body>
</html>
```

## Multi-Level Inheritance

You can create inheritance chains where templates extend other templates that themselves extend base templates:

### Base Template (base.liquid)

```liquid
<html>
<head>
    <title>{% block title %}Base Title{% endblock %}</title>
</head>
<body>
    {% block body %}Base Body{% endblock %}
</body>
</html>
```

### Layout Template (layout.liquid)

```liquid
{% extends "base.liquid" %}

{% block body %}
<div class="container">
    {% block content %}Layout Content{% endblock %}
</div>
{% endblock %}
```

### Page Template (page.liquid)

```liquid
{% extends "layout.liquid" %}

{% block title %}Page Title{% endblock %}

{% block content %}
<p>This is the page content!</p>
{% endblock %}
```

## Using Variables in Blocks

Blocks have access to all template variables:

```liquid
{% extends "article_base.liquid" %}

{% block title %}{{ article.title }} - My Blog{% endblock %}

{% block content %}
<article>
    <h1>{{ article.title }}</h1>
    <p class="date">{{ article.date | date: "%B %d, %Y" }}</p>
    {{ article.content }}
</article>
{% endblock %}
```

## Empty Blocks

You can define empty blocks that child templates may or may not override:

```liquid
<!-- base.liquid -->
{% block scripts %}{% endblock %}

<!-- child.liquid -->
{% extends "base.liquid" %}

{% block scripts %}
<script src="/app.js"></script>
{% endblock %}
```

## API Usage

### Basic Usage

```swift
let engine = LiquidEngine()

// Render with template inheritance
let result = try await engine.renderWithInheritance(
    templatePath: "page.liquid",
    context: ["title": "My Page"],
    baseDirectory: templateDirectory
)
```

### With Absolute Paths

```swift
let engine = LiquidEngine()

// When using absolute paths
let result = try await engine.renderWithInheritance(
    templatePath: "/path/to/template.liquid",
    context: ["data": myData]
)
```

## Best Practices

### 1. Template Organization

Organize templates hierarchically:

```
templates/
├── base.liquid          # Root base template
├── layouts/
│   ├── default.liquid   # Default layout
│   ├── blog.liquid      # Blog layout
│   └── docs.liquid      # Documentation layout
└── pages/
    ├── home.liquid      # Extends layouts/default.liquid
    ├── about.liquid     # Extends layouts/default.liquid
    └── blog/
        └── post.liquid  # Extends layouts/blog.liquid
```

### 2. Naming Conventions

- Use descriptive block names: `{% block main_content %}` instead of `{% block c %}`
- Prefix layout templates with `layout_` or place in a `layouts/` directory
- Use consistent naming patterns across your template hierarchy

### 3. Block Granularity

Create appropriately sized blocks:

```liquid
<!-- Too granular -->
{% block h1_opening_tag %}<h1>{% endblock %}
{% block h1_content %}Title{% endblock %}
{% block h1_closing_tag %}</h1>{% endblock %}

<!-- Better -->
{% block page_title %}
<h1>Title</h1>
{% endblock %}
```

### 4. Default Content

Always provide sensible defaults in parent templates:

```liquid
{% block meta_description %}
<meta name="description" content="Welcome to our website">
{% endblock %}
```

## Performance Considerations

Template inheritance in RhoeLiquid is optimized for performance:

- Templates are parsed once and cached
- Block resolution happens during parsing, not rendering
- Multi-level inheritance has minimal overhead

### Caching

Enable template caching for production:

```swift
let config = LiquidConfiguration()
config.cacheEnabled = true

let engine = LiquidEngine(configuration: config)
```

## Limitations

1. The `{% extends %}` tag must be the first tag in the template
2. You cannot use multiple `{% extends %}` tags
3. Block names must be unique within a template
4. Dynamic template names in `{% extends %}` are not supported

## Error Handling

Common errors and solutions:

### Missing Parent Template

```swift
do {
    let result = try await engine.renderWithInheritance(
        templatePath: "child.liquid",
        context: [:],
        baseDirectory: templatesDir
    )
} catch TemplateLoaderError.templateNotFound(let path) {
    print("Parent template not found: \(path)")
}
```

### Circular Inheritance

RhoeLiquid detects circular inheritance and will throw an error if template A extends B, and B extends A.

## Complete Example

For runnable source-to-output examples, start with the checked-in `Examples/` gallery at the repository root. The language reference also documents the active `extends`, `block`, `include`, and `render` surface without depending on archived demo paths.
