//
//  TemplateInheritance.swift
//  LiquidExtensions
//
//  Handles template inheritance with extends/block functionality
//

import Foundation
import LiquidCore
import LiquidParser

/// Processes template inheritance by resolving extends and merging blocks
public actor TemplateInheritanceProcessor {
    /// The template loader for loading parent templates
    private let templateLoader: TemplateLoader

    /// Registered custom tags that should be recognized in inherited templates.
    private let customTagDescriptors: [CustomTagDescriptor]
    
    /// Cache for processed templates
    private var processedTemplates: [String: ASTNode] = [:]

    /// Tracks the current inheritance chain to prevent circular resolution.
    private var activeTemplateChain: [String] = []
    
    /// Creates a new template inheritance processor
    public init(templateLoader: TemplateLoader, customTagDescriptors: [CustomTagDescriptor] = []) {
        self.templateLoader = templateLoader
        self.customTagDescriptors = customTagDescriptors
    }
    
    /// Processes a template AST to resolve template inheritance
    public func processInheritance(ast: ASTNode, templatePath: String? = nil) async throws -> ASTNode {
        let resolvedTemplatePath: String?
        if let templatePath {
            resolvedTemplatePath = try await templateLoader.resolvedTemplatePath(for: templatePath)
            if let resolvedTemplatePath, activeTemplateChain.contains(resolvedTemplatePath) {
                throw TemplateLoaderError.invalidPath("Circular inheritance detected for template: \(resolvedTemplatePath)")
            }
            if let resolvedTemplatePath {
                activeTemplateChain.append(resolvedTemplatePath)
            }
        } else {
            resolvedTemplatePath = nil
        }
        defer {
            if let resolvedTemplatePath, activeTemplateChain.last == resolvedTemplatePath {
                _ = activeTemplateChain.popLast()
            }
        }

        // Check if this template extends another
        guard case .template(let nodes) = ast else {
            return ast
        }
        
        // Look for extends tag at the beginning
        guard let firstNode = nodes.first,
              case .extends(let parentTemplate) = firstNode else {
            // No inheritance, return as-is
            return ast
        }
        
        // Load parent template
        let (parentPath, parentAST) = try await loadParentTemplate(parentTemplate.string, relativeTo: resolvedTemplatePath)
        
        // Extract blocks from child template
        let childBlocks = extractBlocks(from: Array(nodes.dropFirst()))
        
        // Process parent template recursively (it might also extend another template)
        let processedParent = try await processInheritance(ast: parentAST, templatePath: parentPath)
        
        // Merge child blocks into parent
        return mergeBlocks(parent: processedParent, childBlocks: childBlocks)
    }
    
    /// Loads a parent template
    private func loadParentTemplate(_ templateName: String, relativeTo templatePath: String?) async throws -> (String, ASTNode) {
        let resolvedPath = try await templateLoader.resolvedTemplatePath(for: templateName, relativeTo: templatePath)

        // Check cache first
        if let cached = processedTemplates[resolvedPath] {
            return (resolvedPath, cached)
        }
        
        // Load from disk
        let ast = try await templateLoader.loadTemplateAST(
            templateName,
            relativeTo: templatePath,
            customTagDescriptors: customTagDescriptors
        )
        processedTemplates[resolvedPath] = ast
        return (resolvedPath, ast)
    }
    
    /// Extracts block definitions from a list of nodes
    private func extractBlocks(from nodes: [ASTNode]) -> [String: [ASTNode]] {
        var blocks: [String: [ASTNode]] = [:]
        
        for node in nodes {
            if case .block(let name, let body) = node {
                blocks[name.string] = body
            }
        }
        
        return blocks
    }
    
    /// Merges child blocks into parent template
    private func mergeBlocks(parent: ASTNode, childBlocks: [String: [ASTNode]]) -> ASTNode {
        // First, we need to process the parent template and replace blocks
        return processNode(parent, childBlocks: childBlocks)
    }
    
    /// Processes a node and its children, replacing blocks as needed
    private func processNode(_ node: ASTNode, childBlocks: [String: [ASTNode]]) -> ASTNode {
        switch node {
        case .template(let nodes):
            // Process all nodes in the template
            let processedNodes = nodes.flatMap { processNodeList($0, childBlocks: childBlocks) }
            return .template(processedNodes)
            
        case .block(let name, let parentBody):
            // Replace block with child content if available
            if let childBody = childBlocks[name.string] {
                // Return the child block nodes directly (not wrapped in template)
                return .template(childBody)
            } else {
                // Keep parent block content
                return .template(parentBody)
            }
            
        // For all container nodes, process their children
        case .if(let condition, let thenNodes, let elsif, let elseNodes):
            let processedThen = thenNodes.flatMap { processNodeList($0, childBlocks: childBlocks) }
            let processedElsif = elsif.map { (cond, nodes) in
                (cond, nodes.flatMap { processNodeList($0, childBlocks: childBlocks) })
            }
            let processedElse = elseNodes?.flatMap { processNodeList($0, childBlocks: childBlocks) }
            return .if(condition: condition, then: processedThen, elsif: processedElsif, else: processedElse)
            
        case .unless(let condition, let thenNodes, let elseNodes):
            let processedThen = thenNodes.flatMap { processNodeList($0, childBlocks: childBlocks) }
            let processedElse = elseNodes?.flatMap { processNodeList($0, childBlocks: childBlocks) }
            return .unless(condition: condition, then: processedThen, else: processedElse)
            
        case .for(let variable, let inExpr, let body, let empty, let params):
            let processedBody = body.flatMap { processNodeList($0, childBlocks: childBlocks) }
            let processedEmpty = empty?.flatMap { processNodeList($0, childBlocks: childBlocks) }
            return .for(variable: variable, in: inExpr, body: processedBody, empty: processedEmpty, params: params)
            
        case .capture(let variable, let body):
            let processedBody = body.flatMap { processNodeList($0, childBlocks: childBlocks) }
            return .capture(variable: variable, body: processedBody)
            
        case .liquid(let body):
            let processedBody = body.flatMap { processNodeList($0, childBlocks: childBlocks) }
            return .liquid(body: processedBody)
            
        // Non-container nodes remain unchanged
        default:
            return node
        }
    }
    
    /// Processes a single node and returns a list of nodes (to handle block replacement)
    private func processNodeList(_ node: ASTNode, childBlocks: [String: [ASTNode]]) -> [ASTNode] {
        switch node {
        case .block(let name, let parentBody):
            // Replace block with child content if available
            if let childBody = childBlocks[name.string] {
                // Return the child block nodes directly
                return childBody
            } else {
                // Return parent block content
                return parentBody
            }
        default:
            // Process the node and return it as a single-element array
            return [processNode(node, childBlocks: childBlocks)]
        }
    }
}
