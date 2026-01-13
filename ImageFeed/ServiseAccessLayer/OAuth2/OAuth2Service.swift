import Foundation

private enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {

    static let shared = OAuth2Service()

    private let tokenStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared

    private var task: URLSessionTask?
    private var lastCode: String?

    private(set) var authToken: String? {
        get {
            tokenStorage.token
        }
        set {
            tokenStorage.token = newValue
        }
    }

    private init() {}

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var components = URLComponents(string: "https://unsplash.com/oauth/token") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        guard lastCode != code else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        task?.cancel()
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self]
            (result: Result<OAuthTokenResponseBody, Error>) in

            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let body):
                    self.authToken = body.accessToken
                    completion(.success(body.accessToken))

                case .failure(let error):
                    completion(.failure(error))
                }

                self.task = nil
                self.lastCode = nil
            }
        }

        self.task = task
        task.resume()
    }
}
