//
//  Response.swift
//  Listenbrainz
//
//  Created by Jasjeet Singh on 07/07/25.
//

enum UiState<T> {
    case loading
    case failure(error: Error)
    case success(result: T)
}

func asyncToStream<T>(
    _ operation: @escaping () async throws -> T
) -> AsyncStream<UiState<T>> {
    return AsyncStream { cont in
        cont.yield(.loading)
        Task {
            do {
                let result = try await operation()
                cont.yield(.success(result: result))
            } catch {
                cont.yield(.failure(error: error))
            }
            
            cont.finish()
        }
    }
}

extension AsyncStream {
    func collect(_ block: @escaping (Element) -> Void) async {
        for await value in self {
            block(value)
        }
    }
}
