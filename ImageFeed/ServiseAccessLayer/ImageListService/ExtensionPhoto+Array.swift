import Foundation

extension Photo {
    init(from result: PhotoResult) {
        self.id = result.id
        self.createdAt = ISO8601DateFormatter.imageFeedISO8601.date(from: result.createdAt)
        self.welcomeDescription = result.description
        self.thumbImageURL = result.urls.thumb
        self.largeImageURL = result.urls.full
        self.isLiked = result.likedByUser
        self.size = .zero
    }
}


extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> Array {
        guard index >= 0 && index < count else {
            fatalError("Index out of bounds: \(index)")
        }
        var copy = self
        copy[index] = newValue
        return copy
    }
}

