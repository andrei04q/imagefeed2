import UIKit

extension UIImage {
    enum Image {
        static func image(named: String) -> UIImage? {
            guard let image = UIImage(named: named)
                    
            else {
                assertionFailure("Изображение \(named) не найдено")
                return nil
            }
            return image
        }
    }
}
