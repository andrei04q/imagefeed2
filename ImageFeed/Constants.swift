import Foundation

enum Constants {
    static let accessKey = "T738_bW3vdbv70lxxJ3dl-glgeJTAmpdGF_uyHOJt9A"
    static let secretKey = "INy0XRF-iCjb4QhdT3Hlr3--ngIXbx0nxmN4nLaqYNs"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.unsplash.com") else {
            fatalError("Invalid base URL")
        }
        return url
    }()
}
    