import Foundation
@_exported import Result

public class TravisClient {
    let session: URLSession
    let travis: TravisCloud

    public init(token: String, host: TravisCloud = .org, session: URLSession? = nil) {
        travis = host
        self.session = session ?? URLSession(configuration: TravisClient.makeConfiguration(withToken: token))
    }

    // MARK: Repositories

    public func repositories(forUser user: String, completion: @escaping Completion<[Repository]>) {
        let url = makeURL(path: "/owner/\(user.pathEscape())/repos")
        request(url, completion: completion)
    }

    public func userRepositories(completion: @escaping Completion<[Repository]>) {
        let url = makeURL(path: "/repos")
        request(url, completion: completion)
    }

    // MARK: Active

    public func activeBuilds(completion: @escaping Completion<[Build]>) {
        let url = makeURL(path: "/active")
        request(url, completion: completion)
    }

    // MARK: Jobs

    public func jobs(forBuild identfier: String, completion: @escaping Completion<[Job]>) {
        let url = makeURL(path: "/build/\(identfier.pathEscape())/jobs")
        request(url, completion: completion)
    }

    public func job(withIdentifier identifier: String, completion: @escaping Completion<Job>) {
        let url = makeURL(path: "/job/\(identifier)")
        request(url, completion: completion)
    }

    // restart & cancel job

    // MARK: Repository

    public func repository(_ idOrSlug: String, completion: @escaping Completion<Repository>) {
        let url = makeURL(path: "/repo/\(idOrSlug.pathEscape())", method: .post)
        request(url, completion: completion)
    }

    public func activateRepository(_ idOrSlug: String, completion: @escaping Completion<Repository>) {
        let url = makeURL(path: "/repo/\(idOrSlug.pathEscape())/activate", method: .post)
        request(url, completion: completion)
    }

    public func deactivateRepository(_ idOrSlug: String, completion: @escaping Completion<Repository>) {
        let url = makeURL(path: "/repo/\(idOrSlug.pathEscape())/deactivate", method: .post)
        request(url, completion: completion)
    }

    public func starRepository(_ idOrSlug: String, completion: @escaping Completion<Repository>) {
        let url = makeURL(path: "/repo/\(idOrSlug.pathEscape())/star", method: .post)
        request(url, completion: completion)
    }

    public func unstarRepository(_ idOrSlug: String, completion: @escaping Completion<Repository>) {
        let url = makeURL(path: "/repo/\(idOrSlug.pathEscape())/unstar", method: .post)
        request(url, completion: completion)
    }

    // MARK: Builds

    public func userBuilds(completion: @escaping Completion<[Build]>) {
        let url = makeURL(path: "/builds")
        request(url, completion: completion)
    }

    public func builds(forRepository repoIdOrSlug: String, completion: @escaping Completion<[Build]>) {
        let url = makeURL(path: "/repo/\(repoIdOrSlug.pathEscape())/builds")
        request(url, completion: completion)
    }

    // MARK: Build

    public func build(identifier: String, completion: @escaping Completion<Build>) {
        let url = makeURL(path: "/build/\(identifier)")
        request(url, completion: completion)
    }

    public func restartBuild(identifier: String, completion: @escaping ActionCompletion<MinimalBuild>) {
        let url = makeURL(path: "/build/\(identifier)/restart", method: .post)
        request(url, completion: completion)
    }

    public func cancelBuild(identifier: String, completion: @escaping Completion<MinimalBuild>) {
        let url = makeURL(path: "/build/\(identifier)/cancel", method: .post)
        request(url, completion: completion)
    }

    // MARK: Settings

    public func settings(forRepository repoIdOrSlug: String, completion: @escaping Completion<[Setting]>) {
        let url = makeURL(path: "/repo/\(repoIdOrSlug.pathEscape())/settings")
        request(url, completion: completion)
    }

    // MARK: Links

    public func follow<T: Minimal>(embed: Embed<T>, completion: @escaping Completion<T.Full>) {
        guard let path = embed.path else { return }
        let url = makeURL(path: path)
        request(url, completion: completion)
    }

    // MARK: Requests

    func request<T: Codable>(_ url: URLRequest, completion: @escaping Completion<T>) {
        concreteRequest(url, completion: completion)
    }

    func request<T: Codable>(_ url: URLRequest, completion: @escaping ActionCompletion<T>) {
        concreteRequest(url, completion: completion)
    }

    func concreteRequest<T>(_ url: URLRequest, completion: @escaping ResultCompletion<T>) {
        session.dataTask(with: url) { data, _, _ in
            guard let someData = data else {
                let result: Result<T, TravisError> = Result(error: .noData)
                onMain(completion: completion, result: result)
                return
            }

            do {
                let result = try JSONDecoder().decode(T.self, from: someData)
                onMain(completion: completion, result: .init(result))
            } catch {
                print(error)
                let result: Result<T, TravisError> = Result(error: .unableToDecode(error: error))
                onMain(completion: completion, result: result)
            }
        }.resume()
    }
}

extension TravisClient {
    public static func makeConfiguration(withToken token: String) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Travis-API-Version": "3",
            "Authorization": "token \(token)",
            "User-Agent": "API Explorer",
        ]

        return configuration
    }
}

extension TravisClient {
    func makeURL(path: String, query: [URLQueryItem]? = nil, method: HTTPMethod = .get) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = travis.host
        components.percentEncodedPath = path
        components.queryItems = query

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        return request
    }
}