//
//  DocumentProperties.swift
//  RhoeDOCX
//
//  Complete document properties system for WordprocessingML documents
//  Handles core properties, app properties, and custom properties
//

import Foundation

/// Document properties manager for DOCX documents
public actor DocumentPropertiesManager: Sendable {
    
    /// Core properties (Dublin Core metadata)
    private var coreProperties: WMLCoreProperties?
    
    /// Application properties (Office-specific metadata)
    private var appProperties: WMLAppProperties?
    
    /// Custom properties (user-defined metadata)
    private var customProperties: [String: WMLCustomProperty] = [:]
    
    /// Properties statistics
    private var statistics = DocumentPropertiesStatistics()
    
    public init() {}
    
    // MARK: - Core Properties Management
    
    /// Set core properties
    public func setCoreProperties(_ properties: WMLCoreProperties) {
        coreProperties = properties
        updateStatistics()
    }
    
    /// Get core properties
    public func getCoreProperties() -> WMLCoreProperties? {
        return coreProperties
    }
    
    /// Create core properties with minimal required information
    public func createCoreProperties(
        title: String? = nil,
        subject: String? = nil,
        creator: String? = nil,
        description: String? = nil,
        language: String = "en-US"
    ) -> WMLCoreProperties {
        let now = Date()
        let properties = WMLCoreProperties(
            title: title,
            subject: subject,
            creator: creator,
            keywords: nil,
            description: description,
            lastModifiedBy: creator,
            revision: "1",
            created: now,
            modified: now,
            category: nil,
            contentStatus: nil,
            language: language,
            version: nil
        )
        
        setCoreProperties(properties)
        return properties
    }
    
    /// Update specific core property
    public func updateCoreProperty(
        title: String? = nil,
        subject: String? = nil,
        creator: String? = nil,
        keywords: String? = nil,
        description: String? = nil,
        lastModifiedBy: String? = nil,
        category: String? = nil,
        contentStatus: String? = nil,
        language: String? = nil,
        version: String? = nil
    ) {
        guard var current = coreProperties else { return }
        
        if let title = title { current = WMLCoreProperties(
            title: title, subject: current.subject, creator: current.creator,
            keywords: current.keywords, description: current.description,
            lastModifiedBy: current.lastModifiedBy, revision: current.revision,
            created: current.created, modified: Date(), category: current.category,
            contentStatus: current.contentStatus, language: current.language,
            version: current.version
        )}
        
        if let subject = subject { current = WMLCoreProperties(
            title: current.title, subject: subject, creator: current.creator,
            keywords: current.keywords, description: current.description,
            lastModifiedBy: current.lastModifiedBy, revision: current.revision,
            created: current.created, modified: Date(), category: current.category,
            contentStatus: current.contentStatus, language: current.language,
            version: current.version
        )}
        
        // Update other properties as needed
        coreProperties = current
        updateStatistics()
    }
    
    // MARK: - App Properties Management
    
    /// Set application properties
    public func setAppProperties(_ properties: WMLAppProperties) {
        appProperties = properties
        updateStatistics()
    }
    
    /// Get application properties
    public func getAppProperties() -> WMLAppProperties? {
        return appProperties
    }
    
    /// Create application properties with typical Word document settings
    public func createAppProperties(
        application: String = "Microsoft Office Word",
        appVersion: String = "16.0000",
        template: String? = "Normal.dotm",
        totalTime: Int = 0,
        pages: Int = 1,
        words: Int = 0,
        characters: Int = 0,
        charactersWithSpaces: Int = 0,
        lines: Int = 1,
        paragraphs: Int = 1,
        scaleCrop: Bool = false,
        linksUpToDate: Bool = false,
        sharedDoc: Bool = false,
        hyperlinksChanged: Bool = false
    ) -> WMLAppProperties {
        let properties = WMLAppProperties(
            template: template,
            totalTime: totalTime,
            pages: pages,
            words: words,
            characters: characters,
            charactersWithSpaces: charactersWithSpaces,
            lines: lines,
            paragraphs: paragraphs,
            scaleCrop: scaleCrop,
            company: nil,
            linksUpToDate: linksUpToDate,
            sharedDoc: sharedDoc,
            hyperlinksChanged: hyperlinksChanged,
            appVersion: appVersion,
            docSecurity: .none,
            application: application,
            presentationFormat: nil,
            manager: nil,
            hiddenSlides: nil,
            mmClips: nil,
            notes: nil
        )
        
        setAppProperties(properties)
        return properties
    }
    
    /// Update document statistics in app properties
    public func updateDocumentStatistics(
        pages: Int? = nil,
        words: Int? = nil,
        characters: Int? = nil,
        charactersWithSpaces: Int? = nil,
        lines: Int? = nil,
        paragraphs: Int? = nil
    ) {
        guard var current = appProperties else {
            // Create new app properties with statistics
            _ = createAppProperties(
                pages: pages ?? 1,
                words: words ?? 0,
                characters: characters ?? 0,
                charactersWithSpaces: charactersWithSpaces ?? 0,
                lines: lines ?? 1,
                paragraphs: paragraphs ?? 1
            )
            return
        }
        
        current = WMLAppProperties(
            template: current.template,
            totalTime: current.totalTime,
            pages: pages ?? current.pages,
            words: words ?? current.words,
            characters: characters ?? current.characters,
            charactersWithSpaces: charactersWithSpaces ?? current.charactersWithSpaces,
            lines: lines ?? current.lines,
            paragraphs: paragraphs ?? current.paragraphs,
            scaleCrop: current.scaleCrop,
            company: current.company,
            linksUpToDate: current.linksUpToDate,
            sharedDoc: current.sharedDoc,
            hyperlinksChanged: current.hyperlinksChanged,
            appVersion: current.appVersion,
            docSecurity: current.docSecurity,
            application: current.application,
            presentationFormat: current.presentationFormat,
            manager: current.manager,
            hiddenSlides: current.hiddenSlides,
            mmClips: current.mmClips,
            notes: current.notes
        )
        
        appProperties = current
        updateStatistics()
    }
    
    // MARK: - Custom Properties Management
    
    /// Add custom property
    public func addCustomProperty(name: String, value: WMLCustomPropertyValue) {
        let property = WMLCustomProperty(
            name: name,
            value: value,
            linkTarget: nil
        )
        customProperties[name] = property
        updateStatistics()
    }
    
    /// Get custom property by name
    public func getCustomProperty(name: String) -> WMLCustomProperty? {
        return customProperties[name]
    }
    
    /// Get all custom properties
    public func getAllCustomProperties() -> [WMLCustomProperty] {
        return Array(customProperties.values)
    }
    
    /// Remove custom property
    public func removeCustomProperty(name: String) -> WMLCustomProperty? {
        let removed = customProperties.removeValue(forKey: name)
        if removed != nil {
            updateStatistics()
        }
        return removed
    }
    
    /// Update custom property value
    public func updateCustomProperty(name: String, value: WMLCustomPropertyValue) -> Bool {
        guard customProperties[name] != nil else { return false }
        
        customProperties[name] = WMLCustomProperty(
            name: name,
            value: value,
            linkTarget: customProperties[name]?.linkTarget
        )
        updateStatistics()
        return true
    }
    
    // MARK: - Template Properties
    
    /// Create standard document template properties
    public func createStandardProperties(
        title: String,
        author: String,
        subject: String? = nil,
        description: String? = nil,
        template: DocumentTemplate = .blank
    ) {
        // Create core properties
        _ = createCoreProperties(
            title: title,
            subject: subject,
            creator: author,
            description: description
        )
        
        // Create app properties based on template
        _ = createAppProperties(
            template: template.templateName,
            pages: template.defaultPages,
            paragraphs: template.defaultParagraphs
        )
        
        // Add template-specific custom properties
        for (key, value) in template.customProperties {
            addCustomProperty(name: key, value: value)
        }
    }
    
    // MARK: - Validation
    
    /// Validate all properties for OpenXML compliance
    public func validateProperties() -> DocumentPropertiesValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Validate core properties
        if let core = coreProperties {
            if core.title?.isEmpty == true {
                warnings.append("Core property 'title' is empty")
            }
            
            if core.creator?.isEmpty == true {
                warnings.append("Core property 'creator' is empty")
            }
            
            if core.language.isEmpty {
                errors.append("Core property 'language' is required")
            }
        } else {
            warnings.append("Core properties are not set")
        }
        
        // Validate app properties
        if let app = appProperties {
            if app.application.isEmpty {
                errors.append("App property 'application' is required")
            }
            
            if app.pages < 1 {
                errors.append("App property 'pages' must be at least 1")
            }
            
            if app.words < 0 {
                errors.append("App property 'words' cannot be negative")
            }
        } else {
            warnings.append("Application properties are not set")
        }
        
        // Validate custom properties
        for (name, property) in customProperties {
            if name.isEmpty {
                errors.append("Custom property name cannot be empty")
            }
            
            if case .string(let str) = property.value, str.isEmpty {
                warnings.append("Custom property '\(name)' has empty string value")
            }
        }
        
        return DocumentPropertiesValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            corePropertiesPresent: coreProperties != nil,
            appPropertiesPresent: appProperties != nil,
            customPropertiesCount: customProperties.count
        )
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        statistics.hasCoreProperties = coreProperties != nil
        statistics.hasAppProperties = appProperties != nil
        statistics.customPropertiesCount = customProperties.count
        statistics.lastModified = Date()
        
        // Calculate total properties
        statistics.totalProperties = 0
        if coreProperties != nil { statistics.totalProperties += 1 }
        if appProperties != nil { statistics.totalProperties += 1 }
        statistics.totalProperties += customProperties.count
    }
    
    /// Get properties statistics
    public func getStatistics() -> DocumentPropertiesStatistics {
        return statistics
    }
}

// MARK: - Core Properties

/// Dublin Core metadata properties
public struct WMLCoreProperties: Sendable {
    
    /// Document title
    public let title: String?
    
    /// Document subject
    public let subject: String?
    
    /// Document creator/author
    public let creator: String?
    
    /// Document keywords
    public let keywords: String?
    
    /// Document description
    public let description: String?
    
    /// Last modified by
    public let lastModifiedBy: String?
    
    /// Document revision number
    public let revision: String?
    
    /// Creation date
    public let created: Date?
    
    /// Last modified date
    public let modified: Date?
    
    /// Document category
    public let category: String?
    
    /// Content status
    public let contentStatus: String?
    
    /// Document language
    public let language: String
    
    /// Document version
    public let version: String?
    
    public init(
        title: String? = nil,
        subject: String? = nil,
        creator: String? = nil,
        keywords: String? = nil,
        description: String? = nil,
        lastModifiedBy: String? = nil,
        revision: String? = nil,
        created: Date? = nil,
        modified: Date? = nil,
        category: String? = nil,
        contentStatus: String? = nil,
        language: String = "en-US",
        version: String? = nil
    ) {
        self.title = title
        self.subject = subject
        self.creator = creator
        self.keywords = keywords
        self.description = description
        self.lastModifiedBy = lastModifiedBy
        self.revision = revision
        self.created = created
        self.modified = modified
        self.category = category
        self.contentStatus = contentStatus
        self.language = language
        self.version = version
    }
}

// MARK: - App Properties

/// Application-specific document properties
public struct WMLAppProperties: Sendable {
    
    /// Template used to create document
    public let template: String?
    
    /// Total editing time in minutes
    public let totalTime: Int
    
    /// Number of pages
    public let pages: Int
    
    /// Word count
    public let words: Int
    
    /// Character count (without spaces)
    public let characters: Int
    
    /// Character count (with spaces)
    public let charactersWithSpaces: Int
    
    /// Line count
    public let lines: Int
    
    /// Paragraph count
    public let paragraphs: Int
    
    /// Scale crop setting
    public let scaleCrop: Bool
    
    /// Company name
    public let company: String?
    
    /// Links up to date
    public let linksUpToDate: Bool
    
    /// Shared document
    public let sharedDoc: Bool
    
    /// Hyperlinks changed
    public let hyperlinksChanged: Bool
    
    /// Application version
    public let appVersion: String
    
    /// Document security level
    public let docSecurity: WMLDocumentSecurity
    
    /// Application name
    public let application: String
    
    /// Presentation format
    public let presentationFormat: String?
    
    /// Document manager
    public let manager: String?
    
    /// Hidden slides count
    public let hiddenSlides: Int?
    
    /// Multimedia clips count
    public let mmClips: Int?
    
    /// Notes count
    public let notes: Int?
    
    public init(
        template: String? = nil,
        totalTime: Int = 0,
        pages: Int = 1,
        words: Int = 0,
        characters: Int = 0,
        charactersWithSpaces: Int = 0,
        lines: Int = 1,
        paragraphs: Int = 1,
        scaleCrop: Bool = false,
        company: String? = nil,
        linksUpToDate: Bool = false,
        sharedDoc: Bool = false,
        hyperlinksChanged: Bool = false,
        appVersion: String = "16.0000",
        docSecurity: WMLDocumentSecurity = .none,
        application: String = "Microsoft Office Word",
        presentationFormat: String? = nil,
        manager: String? = nil,
        hiddenSlides: Int? = nil,
        mmClips: Int? = nil,
        notes: Int? = nil
    ) {
        self.template = template
        self.totalTime = totalTime
        self.pages = pages
        self.words = words
        self.characters = characters
        self.charactersWithSpaces = charactersWithSpaces
        self.lines = lines
        self.paragraphs = paragraphs
        self.scaleCrop = scaleCrop
        self.company = company
        self.linksUpToDate = linksUpToDate
        self.sharedDoc = sharedDoc
        self.hyperlinksChanged = hyperlinksChanged
        self.appVersion = appVersion
        self.docSecurity = docSecurity
        self.application = application
        self.presentationFormat = presentationFormat
        self.manager = manager
        self.hiddenSlides = hiddenSlides
        self.mmClips = mmClips
        self.notes = notes
    }
}

/// Document security levels
public enum WMLDocumentSecurity: Int, Sendable, CaseIterable {
    case none = 0
    case passwordProtected = 1
    case readOnlyRecommended = 2
    case readOnlyEnforced = 4
    case lockedForAnnotations = 8
}

// MARK: - Custom Properties

/// Custom document property
public struct WMLCustomProperty: Sendable {
    
    /// Property name
    public let name: String
    
    /// Property value
    public let value: WMLCustomPropertyValue
    
    /// Link target for linked properties
    public let linkTarget: String?
    
    public init(name: String, value: WMLCustomPropertyValue, linkTarget: String? = nil) {
        self.name = name
        self.value = value
        self.linkTarget = linkTarget
    }
}

/// Custom property value types
public enum WMLCustomPropertyValue: Sendable {
    case string(String)
    case integer(Int)
    case float(Double)
    case date(Date)
    case boolean(Bool)
    
    /// Get string representation
    public var stringValue: String {
        switch self {
        case .string(let str): return str
        case .integer(let int): return String(int)
        case .float(let double): return String(double)
        case .date(let date): return ISO8601DateFormatter().string(from: date)
        case .boolean(let bool): return bool ? "true" : "false"
        }
    }
    
    /// Get type name
    public var typeName: String {
        switch self {
        case .string: return "string"
        case .integer: return "integer"
        case .float: return "float"
        case .date: return "date"
        case .boolean: return "boolean"
        }
    }
}

// MARK: - Document Templates

/// Predefined document templates with standard properties
public enum DocumentTemplate: Sendable, CaseIterable {
    case blank
    case letter
    case memo
    case report
    case resume
    case brochure
    case newsletter
    
    /// Template file name
    public var templateName: String {
        switch self {
        case .blank: return "Normal.dotm"
        case .letter: return "Letter.dotx"
        case .memo: return "Memo.dotx"
        case .report: return "Report.dotx"
        case .resume: return "Resume.dotx"
        case .brochure: return "Brochure.dotx"
        case .newsletter: return "Newsletter.dotx"
        }
    }
    
    /// Default page count for template
    public var defaultPages: Int {
        switch self {
        case .blank, .letter, .memo: return 1
        case .report, .resume: return 2
        case .brochure: return 3
        case .newsletter: return 4
        }
    }
    
    /// Default paragraph count for template
    public var defaultParagraphs: Int {
        switch self {
        case .blank: return 1
        case .letter: return 5
        case .memo: return 3
        case .report: return 15
        case .resume: return 20
        case .brochure: return 25
        case .newsletter: return 30
        }
    }
    
    /// Template-specific custom properties
    public var customProperties: [String: WMLCustomPropertyValue] {
        switch self {
        case .blank:
            return [:]
        case .letter:
            return [
                "DocumentType": .string("Business Letter"),
                "FormattingStyle": .string("Professional")
            ]
        case .memo:
            return [
                "DocumentType": .string("Memorandum"),
                "Distribution": .string("Internal")
            ]
        case .report:
            return [
                "DocumentType": .string("Report"),
                "ReportType": .string("Standard"),
                "HasTableOfContents": .boolean(true)
            ]
        case .resume:
            return [
                "DocumentType": .string("Resume"),
                "Format": .string("Chronological")
            ]
        case .brochure:
            return [
                "DocumentType": .string("Brochure"),
                "Layout": .string("Tri-fold"),
                "Orientation": .string("Landscape")
            ]
        case .newsletter:
            return [
                "DocumentType": .string("Newsletter"),
                "Columns": .integer(2),
                "Frequency": .string("Monthly")
            ]
        }
    }
}

// MARK: - Statistics and Validation

/// Document properties statistics
public struct DocumentPropertiesStatistics: Sendable {
    
    /// Whether core properties are set
    public var hasCoreProperties: Bool = false
    
    /// Whether app properties are set
    public var hasAppProperties: Bool = false
    
    /// Number of custom properties
    public var customPropertiesCount: Int = 0
    
    /// Total properties count
    public var totalProperties: Int = 0
    
    /// Last modification time
    public var lastModified: Date?
    
    /// Human-readable summary
    public var summary: String {
        var parts: [String] = []
        
        if hasCoreProperties { parts.append("core") }
        if hasAppProperties { parts.append("app") }
        if customPropertiesCount > 0 { parts.append("\(customPropertiesCount) custom") }
        
        if parts.isEmpty {
            return "No properties set"
        } else {
            return "\(totalProperties) properties (\(parts.joined(separator: ", ")))"
        }
    }
}

/// Document properties validation result
public struct DocumentPropertiesValidationResult: Sendable {
    
    /// Whether all properties are valid
    public let isValid: Bool
    
    /// Validation errors
    public let errors: [String]
    
    /// Validation warnings
    public let warnings: [String]
    
    /// Whether core properties are present
    public let corePropertiesPresent: Bool
    
    /// Whether app properties are present
    public let appPropertiesPresent: Bool
    
    /// Number of custom properties
    public let customPropertiesCount: Int
    
    /// Human-readable summary
    public var summary: String {
        if isValid && errors.isEmpty && warnings.isEmpty {
            return "✅ All properties valid"
        } else {
            var parts: [String] = []
            if !errors.isEmpty { parts.append("\(errors.count) errors") }
            if !warnings.isEmpty { parts.append("\(warnings.count) warnings") }
            
            let status = isValid ? "⚠️" : "❌"
            return "\(status) \(parts.joined(separator: ", "))"
        }
    }
}

// MARK: - Properties Errors

/// Document properties related errors
public enum DocumentPropertiesError: Error, Sendable {
    case invalidPropertyName(String)
    case invalidPropertyValue(String, String)
    case missingRequiredProperty(String)
    case propertyNotFound(String)
    case invalidPropertyType(String, expected: String, actual: String)
    case propertiesNotFound
}

extension DocumentPropertiesError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPropertyName(let name):
            return "Invalid property name: \(name)"
        case .invalidPropertyValue(let name, let reason):
            return "Invalid value for property '\(name)': \(reason)"
        case .missingRequiredProperty(let name):
            return "Missing required property: \(name)"
        case .propertyNotFound(let name):
            return "Property not found: \(name)"
        case .invalidPropertyType(let name, let expected, let actual):
            return "Invalid type for property '\(name)': expected \(expected), got \(actual)"
        case .propertiesNotFound:
            return "Document properties not found"
        }
    }
}
