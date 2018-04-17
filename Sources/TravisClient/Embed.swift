/// Minimal Representations are embbeded into the main object returned from the API.
/// The Embed object contains the meta data
public struct Embed<T: Codable>: Codable, ObjectSubscriptable {
    public let type: String
    public let path: String?
    public let object: T

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case path = "@href"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        object = try T(from: decoder)
    }
}
