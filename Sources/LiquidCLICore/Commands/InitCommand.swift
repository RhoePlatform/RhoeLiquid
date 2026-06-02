//
//  InitCommand.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import ArgumentParser
import Foundation
import RhoeLiquid

public struct InitCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new Liquid template project.",
        discussion: """
        Creates a small RhoeLiquid starter project with templates, sample JSON \
        data, README guidance, and optional git initialization.
        """
    )

    @Argument(help: "Project directory name.")
    public var name: String

    @Option(
        name: .long,
        help: "Project type: simple, web, api, or documentation.",
        completion: ProjectType.completion
    )
    public var type: ProjectType = .simple

    @Flag(name: .long, help: "Initialize a git repository.")
    public var git: Bool = false

    public init() {}

    public func run() async throws {
        let fm = FileManager.default
        let projectPath = (fm.currentDirectoryPath as NSString).appendingPathComponent(name)

        guard !fm.fileExists(atPath: projectPath) else {
            TerminalUI.error("Directory '\(name)' already exists")
            throw ExitCode.failure
        }

        TerminalUI.header("Creating project: \(name)")
        print("  Type: \(type.rawValue)")
        print("")

        // Create directory structure
        let dirs = directoryStructure(for: type)
        for dir in dirs {
            let path = (projectPath as NSString).appendingPathComponent(dir)
            try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
            TerminalUI.success("Created \(dir)/")
        }

        // Generate files
        let files = templateFiles(for: type, projectName: name)
        for (relativePath, content) in files {
            let path = (projectPath as NSString).appendingPathComponent(relativePath)
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            TerminalUI.success("Created \(relativePath)")
        }

        // Git init
        if git {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["init", projectPath]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                TerminalUI.success("Initialized git repository")
            }
        }

        print("")
        TerminalUI.success("Project '\(name)' created successfully!")
        print("\n  cd \(name)")
        print("  liquid render templates/index.liquid")
    }

    private func directoryStructure(for type: ProjectType) -> [String] {
        var dirs = ["templates", "data", "output"]
        switch type {
        case .web:
            dirs += ["templates/layouts", "templates/partials", "templates/pages", "assets/css", "assets/js"]
        case .api:
            dirs += ["templates/responses", "templates/errors", "schemas"]
        case .documentation:
            dirs += ["templates/layouts", "templates/pages", "templates/components", "content"]
        case .simple:
            break
        }
        return dirs
    }

    // swiftlint:disable function_body_length
    private func templateFiles(for type: ProjectType, projectName: String) -> [(String, String)] {
        var files: [(String, String)] = []

        // liquid.json config
        files.append(("liquid.json", """
        {
            "name": "\(projectName)",
            "type": "\(type.rawValue)",
            "templateDir": "templates",
            "dataDir": "data",
            "outputDir": "output"
        }
        """))

        // README
        files.append(("README.md", """
        # \(projectName)

        A Liquid template project powered by RhoeLiquid.

        ## Quick Start

        ```bash
        liquid render templates/index.liquid --context data/site.json
        ```

        ## Structure

        - `templates/` -- Liquid template files
        - `data/` -- JSON context data
        - `output/` -- Rendered output
        """))

        // .gitignore
        files.append((".gitignore", """
        output/
        .build/
        .DS_Store
        """))

        // Example template
        switch type {
        case .web:
            files.append(("templates/layouts/base.liquid", """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <title>{{ page.title | default: "\(projectName)" }}</title>
            </head>
            <body>
                <header>
                    <h1>{{ site.name }}</h1>
                    <nav>
                        {% for item in site.nav %}
                        <a href="{{ item.url }}">{{ item.title }}</a>
                        {% endfor %}
                    </nav>
                </header>
                <main>
                    {{ content }}
                </main>
                <footer>
                    <p>&copy; {{ "now" | date: "%Y" }} {{ site.name }}</p>
                </footer>
            </body>
            </html>
            """))
            files.append(("templates/pages/index.liquid", """
            {% assign page_title = "Home" %}
            <h2>Welcome to {{ site.name }}</h2>
            <p>{{ site.description }}</p>

            {% if site.features %}
            <ul>
                {% for feature in site.features %}
                <li>{{ feature }}</li>
                {% endfor %}
            </ul>
            {% endif %}
            """))
            files.append(("data/site.json", """
            {
                "site": {
                    "name": "\(projectName)",
                    "description": "A modern web project built with Liquid templates.",
                    "nav": [
                        {"title": "Home", "url": "/"},
                        {"title": "About", "url": "/about"}
                    ],
                    "features": ["Fast rendering", "Template inheritance", "50+ filters"]
                }
            }
            """))
        case .api:
            files.append(("templates/responses/success.liquid", """
            {
                "status": "success",
                "data": {{ data | json }},
                "meta": {
                    "timestamp": "{{ "now" | date: "%Y-%m-%dT%H:%M:%S" }}",
                    "version": "{{ api.version | default: "1.0" }}"
                }
            }
            """))
            files.append(("templates/errors/error.liquid", """
            {
                "status": "error",
                "error": {
                    "code": {{ error.code }},
                    "message": "{{ error.message | escape }}"
                }
            }
            """))
            files.append(("data/site.json", """
            {
                "api": {"version": "1.0"},
                "data": {"message": "Hello from \(projectName)"},
                "error": {"code": 404, "message": "Not found"}
            }
            """))
        case .documentation:
            files.append(("templates/pages/index.liquid", """
            # {{ site.name }} Documentation

            {{ site.description }}

            ## Getting Started

            {% for section in site.sections %}
            ### {{ section.title }}

            {{ section.content }}

            {% endfor %}
            """))
            files.append(("data/site.json", """
            {
                "site": {
                    "name": "\(projectName)",
                    "description": "Project documentation.",
                    "sections": [
                        {"title": "Installation", "content": "Run `swift build` to get started."},
                        {"title": "Usage", "content": "See the examples directory for templates."}
                    ]
                }
            }
            """))
        case .simple:
            files.append(("templates/index.liquid", """
            Hello, {{ name | default: "World" }}!

            {% if items %}
            Items:
            {% for item in items %}
              - {{ item }}
            {% endfor %}
            {% endif %}
            """))
            files.append(("data/site.json", """
            {
                "name": "RhoeLiquid",
                "items": ["Fast", "Safe", "Modern"]
            }
            """))
        }

        return files
    }
    // swiftlint:enable function_body_length
}
