import Foundation

public enum JSONRPC {
    public static let version = "2.0"

    public enum ErrorCode {
        public static let parseError = -32700
        public static let invalidRequest = -32600
        public static let methodNotFound = -32601
        public static let invalidParams = -32602
        public static let internalError = -32603
    }

    public static func responseEnvelope(id: Any?, result: [String: Any]) -> [String: Any] {
        var envelope: [String: Any] = ["jsonrpc": version, "result": result]
        if let id = id { envelope["id"] = id }
        return envelope
    }

    public static func errorEnvelope(id: Any?, code: Int, message: String, data: Any? = nil) -> [String: Any] {
        var error: [String: Any] = ["code": code, "message": message]
        if let data = data { error["data"] = data }
        var envelope: [String: Any] = ["jsonrpc": version, "error": error]
        envelope["id"] = id ?? NSNull()
        return envelope
    }

    public static func encode(_ payload: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: payload, options: [.withoutEscapingSlashes])
    }

    public static func decode(_ data: Data) throws -> [String: Any] {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "deinitive.jsonrpc", code: 1, userInfo: [NSLocalizedDescriptionKey: "expected JSON object"])
        }
        return object
    }
}
