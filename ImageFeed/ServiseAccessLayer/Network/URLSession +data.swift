import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
                print("[URLSession.data]: NetworkError ошибка запроса: \(error.localizedDescription) for \(request.url?.absoluteString ?? "nil")")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(status)))
                print("[URLSession.data]: NetworkError ошибка ответа: \(status) for \(request.url?.absoluteString ?? "nil")")
                return
            }
            
            guard let data = data else {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
                print("[URLSession.data]: NetworkError нет данных: \(request.url?.absoluteString ?? "nil")")
                return
            }
            fulfillCompletionOnTheMainThread(.success(data))
        })
        
        return task
    }
}

extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Полеченные данные: \(jsonString)")
                }
                do {
                    let decodedOject = try decoder.decode(T.self, from: data)
                    completion(.success(decodedOject))
                }
                catch {
                    if let decodingError = error as? DecodingError {
                        print("[URLSession.objectTask]: Ошибка декодирования 1: \(decodingError), Данные: \(String(data: data, encoding: .utf8) ?? "")")
                    } else {
                        print("[URLSession.objectTask]: Ошибка декодирования 2: \(error.localizedDescription), Данные: \(String(data: data, encoding: .utf8) ?? "")")
                    }
                    completion(.failure(error))
                }
            case . failure(let error):
                print("[URLSession.objectTask]: Ошибка запроса 3: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        return task
    }
}
