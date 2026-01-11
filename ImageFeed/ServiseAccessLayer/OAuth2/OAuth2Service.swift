import Foundation

private enum AuthServiceError: Error {
    case invalidRequest
    case invalidResponse
    case noData
}

final class OAuth2Service {
    
    static let shared = OAuth2Service ()
    
    private let tokenStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared

    private var task: URLSessionTask?

    private var lastCode: String?

    private(set) var authToken: String? {
        get {
            return tokenStorage.token
        }
        set {
            tokenStorage.token = newValue
        }
    }
    
    private init() { }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard
            var components = URLComponents(string: "https://unsplash.com/oauth/token")
        else {
            assertionFailure("Failed to create URL")
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let authTokenUrl = components.url else {
            return nil
        }
        
        var request =  URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
        
        print("Реквест", request)
        return request
    }
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        assert(Thread.isMainThread)
        guard lastCode != code else {
            completion(.failure(AuthServiceError.invalidRequest))
            print("[fetchOAuthToken]: AuthServiceError - lastCode == code")
            return
        }
        task?.cancel()
        lastCode = code
        
        guard
            let request = makeOAuthTokenRequest(code: code)
        else {
            completion(.failure(AuthServiceError.invalidRequest))
            print("[fetchOAuthToken]: AuthServiceError ошибка конфигурации запроса")
            return
        }
        
        let task  = urlSession.objectTask(for: request) { [weak self]
            (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken
                    completion(.success(authToken))
                               
                               self.task = nil
                               self.lastCode = nil
                case .failure(let error):
                    print("[fetchOAuthToken]: Ошибка запроса: \(error.localizedDescription)")
                    completion(.failure(error))
                               
                    self.task = nil
                    self.lastCode = nil
                }
            }
        }
        self.task = task
        task.resume()
    }
    
    private struct OAuthTokenResponseBody: Codable {
            let accessToken: String
            let tokenType: String
            let refreshToken: String?
            let scope: String
            let createdAt: Int
            let userId: Int
            let username: String
    }
}


extension OAuth2Service {
    private func object(for request: URLRequest, completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void) -> URLSessionTask {
        
        let decoder = JSONDecoder()
        return urlSession.data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    completion(.success(body))
                }
                catch {
                    completion(.failure(NetworkError.decodingError(error)))
                    print("[OAuth2Service.object]: Ошибка декодирования: \(error.localizedDescription)")
                }
            case .failure(let error):
                completion(.failure(error))
                print("[OAuth2Service.object]: Ошибка преобразования в модель: \(error.localizedDescription)")
            }
        }
    }
}
