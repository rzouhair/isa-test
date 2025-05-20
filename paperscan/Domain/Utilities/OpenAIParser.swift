import Foundation

// MARK: - Base Models

/// Base protocol for all OpenAI responses
protocol OpenAIResponse: Codable, Identifiable {
    var id: String? { get }
    var object: String? { get }
    var createdAt: Int? { get }
    var status: String? { get }
    var error: String? { get }
    var incompleteDetails: String? { get }
    var instructions: String? { get }
    var maxOutputTokens: Int? { get }
    var model: String? { get }
    var parallelToolCalls: Bool? { get }
    var previousResponseId: String? { get }
    var reasoning: Reasoning? { get }
    var store: Bool? { get }
    var temperature: Double? { get }
    var text: TextFormat? { get }
    var toolChoice: String? { get }
    var topP: Double? { get }
    var truncation: String? { get }
    var usage: Usage? { get }
    var user: String? { get }
    var metadata: [String: String]? { get }
}

/// Base Response Model
struct BaseResponseModel: OpenAIResponse {
    let id: String?
    let object: String?
    let createdAt: Int?
    let status: String?
    let error: String?
    let incompleteDetails: String?
    let instructions: String?
    let maxOutputTokens: Int?
    let model: String?
    let output: [OutputItem]?
    let parallelToolCalls: Bool?
    let previousResponseId: String?
    let reasoning: Reasoning?
    let store: Bool?
    let temperature: Double?
    let text: TextFormat?
    let toolChoice: String?
    let tools: [Tool]?
    let topP: Double?
    let truncation: String?
    let usage: Usage?
    let user: String?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, object, status, error, model, output, store, temperature, text, tools, truncation, usage, user, metadata
        case createdAt = "created_at"
        case incompleteDetails = "incomplete_details"
        case instructions
        case maxOutputTokens = "max_output_tokens"
        case parallelToolCalls = "parallel_tool_calls"
        case previousResponseId = "previous_response_id"
        case reasoning
        case toolChoice = "tool_choice"
        case topP = "top_p"
    }
}

// MARK: - Shared Models

struct Reasoning: Codable {
    let effort: String?
    let generateSummary: String?
    
    enum CodingKeys: String, CodingKey {
        case effort
        case generateSummary = "generate_summary"
    }
}

struct TextFormat: Codable {
    let format: Format
}

struct Format: Codable {
    let type: String
}

struct Usage: Codable {
    let inputTokens: Int
    let inputTokensDetails: InputTokensDetails?
    let outputTokens: Int
    let outputTokensDetails: OutputTokensDetails
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case inputTokensDetails = "input_tokens_details"
        case outputTokens = "output_tokens"
        case outputTokensDetails = "output_tokens_details"
        case totalTokens = "total_tokens"
    }
}

struct InputTokensDetails: Codable {
    let cachedTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case cachedTokens = "cached_tokens"
    }
}

struct OutputTokensDetails: Codable {
    let reasoningTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case reasoningTokens = "reasoning_tokens"
    }
}

// MARK: - Output Types

/// Base protocol for all output items
protocol OutputItemProtocol: Codable, Identifiable {
    var type: String { get }
    var id: String { get }
}

/// Generic Output Item - automatically handles different types
struct OutputItem: Codable, Identifiable {
    let type: String
    let id: String
    let status: String?
    
    // Message specific
    let role: String?
    let content: [ResponseContent]?
    
    // Function call specific
    let callId: String?
    let name: String?
    let arguments: String?
    
    enum CodingKeys: String, CodingKey {
        case type, id, status, role, content
        case callId = "call_id"
        case name, arguments
    }
    
    /// Returns the output as a message, if applicable
    var asMessage: MessageOutput? {
        guard type == "message",
              let role = role,
              let content = content else {
            return nil
        }
        
        return MessageOutput(
            type: type,
            id: id,
            status: status ?? "unknown",
            role: role,
            content: content
        )
    }
    
    /// Returns the output as a function call, if applicable
    var asFunctionCall: FunctionCallOutput? {
        guard type == "function_call",
              let callId = callId,
              let name = name,
              let arguments = arguments else {
            return nil
        }
        
        return FunctionCallOutput(
            type: type,
            id: id,
            callId: callId,
            name: name,
            arguments: arguments,
            status: status ?? "unknown"
        )
    }
    
    /// Returns the output as a web search call, if applicable
    var asWebSearchCall: WebSearchCallOutput? {
        guard type == "web_search_call" else {
            return nil
        }
        
        return WebSearchCallOutput(
            type: type,
            id: id,
            status: status ?? "unknown"
        )
    }
}

/// Message Output
struct MessageOutput: OutputItemProtocol {
    let type: String
    let id: String
    let status: String
    let role: String
    let content: [ResponseContent]
}

/// Function Call Output
public struct FunctionCallOutput: OutputItemProtocol {
    let type: String
    public let id: String
    let callId: String
    let name: String
    let arguments: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case type, id, name, arguments, status
        case callId = "call_id"
    }
    
    /// Parse the arguments string into a dictionary
    func parsedArguments<T: Decodable>() -> T? {
        guard let data = arguments.data(using: .utf8) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Error parsing function arguments: \(error)")
            return nil
        }
    }
}

/// Web Search Call Output
struct WebSearchCallOutput: OutputItemProtocol {
    let type: String
    let id: String
    let status: String
}

/// Content item within a message
struct ResponseContent: Codable {
    let type: String
    let text: String
    let annotations: [Annotation]
}

/// Annotation types
enum Annotation: Codable {
    case urlCitation(URLCitation)
    
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "url_citation":
            self = .urlCitation(try URLCitation(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown annotation type: \(type)"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .urlCitation(let citation):
            try container.encode("url_citation", forKey: .type)
            try citation.encode(to: encoder)
        }
    }
}

/// URL Citation annotation
struct URLCitation: Codable {
    let type: String
    let startIndex: Int
    let endIndex: Int
    let url: String
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case startIndex = "start_index"
        case endIndex = "end_index"
        case url, title
    }
}

public struct CitationResult {
    let text: String
    let citations: [URLCitation]
}


// MARK: - Tool Types

/// Base protocol for all tools
protocol ToolProtocol: Codable {
    var type: String { get }
}

/// Generic Tool - automatically handles different types
struct Tool: Codable {
    let type: String
    
    // Function specific
    let description: String?
    let name: String?
    let parameters: JSONObject?
    let strict: Bool?
    
    // Web search specific
    let domains: [String]?
    let searchContextSize: String?
    let userLocation: UserLocation?
    
    enum CodingKeys: String, CodingKey {
        case type, description, name, parameters, strict, domains
        case searchContextSize = "search_context_size"
        case userLocation = "user_location"
    }
    
    /// Returns the tool as a function, if applicable
    var asFunction: FunctionTool? {
        guard type == "function",
              let name = name,
              let description = description,
              let parameters = parameters else {
            return nil
        }
        
        return FunctionTool(
            type: type,
            name: name,
            description: description,
            parameters: parameters,
            strict: strict ?? false
        )
    }
    
    /// Returns the tool as a web search, if applicable
    var asWebSearch: WebSearchTool? {
        guard type == "web_search_preview" else {
            return nil
        }
        
        return WebSearchTool(
            type: type,
            domains: domains ?? [],
            searchContextSize: searchContextSize ?? "medium",
            userLocation: userLocation
        )
    }
}

/// JSON Object wrapper for handling dynamic JSON
struct JSONObject: Codable {
    let value: [String: Any]
    
    init(_ value: [String: Any]) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var result: [String: Any] = [:]
        
        for key in container.allKeys {
            if let boolValue = try? container.decode(Bool.self, forKey: key) {
                result[key.stringValue] = boolValue
            } else if let intValue = try? container.decode(Int.self, forKey: key) {
                result[key.stringValue] = intValue
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                result[key.stringValue] = doubleValue
            } else if let stringValue = try? container.decode(String.self, forKey: key) {
                result[key.stringValue] = stringValue
            } else if let nestedDictionary = try? container.decode(JSONObject.self, forKey: key) {
                result[key.stringValue] = nestedDictionary.value
            } else if let nestedArray = try? container.decode([JSONObject].self, forKey: key) {
                result[key.stringValue] = nestedArray.map { $0.value }
            } else if let stringArray = try? container.decode([String].self, forKey: key) {
                result[key.stringValue] = stringArray
            } else if container.contains(key) {
                // Handle null values
                result[key.stringValue] = NSNull()
            }
        }
        
        self.value = result
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        
        for (key, value) in value {
            let codingKey = DynamicCodingKeys(stringValue: key)
            
            switch value {
            case let value as Bool:
                try container.encode(value, forKey: codingKey)
            case let value as Int:
                try container.encode(value, forKey: codingKey)
            case let value as Double:
                try container.encode(value, forKey: codingKey)
            case let value as String:
                try container.encode(value, forKey: codingKey)
            case let value as [String: Any]:
                try container.encode(JSONObject(value), forKey: codingKey)
            case let value as [Any]:
                try container.encode(value.map { $0 as? [String: Any] }.compactMap { $0 != nil ? JSONObject($0!) : nil }, forKey: codingKey)
            case is NSNull:
                try container.encodeNil(forKey: codingKey)
            default:
                print("Unsupported type for key \(key)")
            }
        }
    }
    
    struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}

/// Function Tool
struct FunctionTool: ToolProtocol {
    let type: String
    let name: String
    let description: String
    let parameters: JSONObject
    let strict: Bool
    
    /// Parse function parameters into a specific type
    func parametersAs<T: Decodable>() -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters.value)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Error parsing function parameters: \(error)")
            return nil
        }
    }
}

/// Web Search Tool
struct WebSearchTool: ToolProtocol {
    let type: String
    let domains: [String]
    let searchContextSize: String
    let userLocation: UserLocation?
    
    enum CodingKeys: String, CodingKey {
        case type, domains
        case searchContextSize = "search_context_size"
        case userLocation = "user_location"
    }
}

/// User Location for Web Search
struct UserLocation: Codable {
    let type: String
    let city: String?
    let country: String?
    let region: String?
    let timezone: String?
}

// MARK: - Specialized Response Types

/// Text Response - Standard text response
struct TextResponse: Decodable {
    let baseResponse: BaseResponseModel
    
    var textContent: String? {
        // Get the first message output
        guard let messageOutput = baseResponse.output?.first?.asMessage,
              let firstContent = messageOutput.content.first else {
            return nil
        }
        
        return firstContent.text
    }
    
    init(from decoder: Decoder) throws {
        baseResponse = try BaseResponseModel(from: decoder)
    }
}

/// Web Search Response - Response with web search results
public struct WebSearchResponse: Decodable {
    let baseResponse: BaseResponseModel
    
    var webSearchCall: WebSearchCallOutput? {
        // Find the web search call output
        return baseResponse.output?.compactMap { $0.asWebSearchCall }.first
    }

    var messageWithCitations: CitationResult? {
        // Get the message output (usually comes after the web search call)
        guard let messageIndex = baseResponse.output?.firstIndex(where: { $0.type == "message" }),
              let messageOutput = baseResponse.output?[messageIndex].asMessage,
              let content = messageOutput.content.first else {
            return nil
        }
        
        // Extract citations
        let citations = content.annotations.compactMap { annotation -> URLCitation? in
            if case .urlCitation(let citation) = annotation {
                return URLCitation(type: citation.type, startIndex: citation.startIndex, endIndex: citation.endIndex, url: citation.url.replaceQueryItemWith(name: "utm_source", with: "paperscan") ?? "#", title: citation.title)
            }
            return nil
        }
        
        return CitationResult(text: content.text, citations: citations)
    }
    
    public init(from decoder: Decoder) throws {
        baseResponse = try BaseResponseModel(from: decoder)
    }
}

/// Function Call Response - Response with function calls
struct FunctionCallResponse: Decodable {
    let baseResponse: BaseResponseModel
    
    var functionCall: FunctionCallOutput? {
        // Get the function call output
        return baseResponse.output?.compactMap { $0.asFunctionCall }.first
    }
    
    var functionDefinition: FunctionTool? {
        // Get the function tool definition
        return baseResponse.tools?.compactMap { $0.asFunction }.first
    }
    
    init(from decoder: Decoder) throws {
        baseResponse = try BaseResponseModel(from: decoder)
    }
}

extension AIServiceProvider {
    func parseOpenAIResponse(jsonString: String) -> Any? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return nil
        }
        
        let decoder = JSONDecoder()
        
        // First try to decode as base response to detect type
        do {
            let baseResponse = try decoder.decode(BaseResponseModel.self, from: jsonData)
            print(baseResponse)
            
            guard let output = baseResponse.output else {
                print("No output found in response")
                return nil
            }
            // Check for function call
            if output.contains(where: { $0.type == "function_call" }) {
                return try decoder.decode(FunctionCallResponse.self, from: jsonData)
            }
            
            // Check for web search
            if output.contains(where: { $0.type == "web_search_call" }) {
                return try decoder.decode(WebSearchResponse.self, from: jsonData)
            }
            
            // Default to text response (could be image analysis too, but structure is the same)
            return try decoder.decode(TextResponse.self, from: jsonData)
            
        } catch {
            print("Error decoding OpenAI response: \(error)")
            return nil
        }
    }

    // MARK: - Example Usage

    func exampleUsage() {
        // Example JSON strings would go here (abbreviated for clarity)
        let textResponseJson = """
        {"id": "resp_67ccd2bed1ec8190b14f964abc0542670bb6a6b452d3795b", "output": [{"type": "message", "content": [{"type": "output_text", "text": "In a peaceful grove..."}]}]}
        """
        
        // Parse the response
        if let response = parseOpenAIResponse(jsonString: textResponseJson) as? TextResponse {
            print("Text content: \(response.textContent ?? "None")")
        }
        
        // Similar examples for other response types...
    }

}
