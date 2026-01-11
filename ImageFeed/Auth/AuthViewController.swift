import UIKit
import ProgressHUD

protocol AuthViewControlletDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    weak var delegate: AuthViewControlletDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "YP Black")
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        
        UIBlockingProgressHUD.show()
        fetchOAuthToken(code) { [weak self] result in
            
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            switch result {
            case .success(let token):
                if let delegate = self.delegate {
                                delegate.didAuthenticate(self)
                            } else {
                                
                                self.switchToTabBarController()
                            }
                print("Токен получен: \(token)")
            case let .failure(error):
                print("Ошибка при аунтефикации: \(error.localizedDescription)")
                self.showAuthErrorAlert()
            }
            
            UIBlockingProgressHUD.dismiss()
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}

extension AuthViewController {
    private func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        OAuth2Service.shared.fetchOAuthToken(code) { result in
            completion(result)
        }
    }
}

extension AuthViewController {
    func showAuthErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "Ок",
            style: .default,
            handler: nil
        )
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension AuthViewController {
    private func switchToTabBarController() {
        guard
            let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
            let window = sceneDelegate.window else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        let appearace = UITabBarAppearance()
        appearace.configureWithOpaqueBackground()
        appearace.backgroundColor = UIColor(named: "YP Black")
        appearace.stackedLayoutAppearance.normal.iconColor = .ypWhite
        appearace.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.ypWhite]
        appearace.stackedLayoutAppearance.selected.iconColor = .ypBlue
        appearace.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.ypBlue]
        
        UITabBar.appearance().standardAppearance = appearace
        UITabBar.appearance().scrollEdgeAppearance = appearace
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "TabBarViewController")
        
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}
