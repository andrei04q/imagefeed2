import UIKit

final class SplashViewController: UIViewController, UINavigationControllerDelegate {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let profileServise = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSplash()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            presentAuthViewController()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupSplash() {
        view.backgroundColor = UIColor(named: "YP Black")
        
        let splashImageView: UIImageView  = {
            let imageView = UIImageView(
                image: UIImage(named: "splash_screen_logo")
            )
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            return imageView

        }()
        
        view.addSubview(splashImageView)
        NSLayoutConstraint.activate([
            splashImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            splashImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func presentAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: "NavigationController") as? UINavigationController else {
            assertionFailure("Не удалось найти NavigationController по идентификатору")
            return
        }
        if let navigationController = navigationController.viewControllers.first as? AuthViewController {
            navigationController.delegate = self
        }
        
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    private func switchToTabBarController() {
       
        
        let appearace = UITabBarAppearance()
        appearace.configureWithOpaqueBackground()
        appearace.backgroundColor = UIColor(named: "YP Black")
        appearace.stackedLayoutAppearance.normal.iconColor = .ypWhite
        appearace.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.ypWhite]
        appearace.stackedLayoutAppearance.selected.iconColor = .ypBlue
        appearace.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.ypBlue]
        
        UITabBar.appearance().standardAppearance = appearace
        UITabBar.appearance().scrollEdgeAppearance = appearace
        
        guard
            let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
            let window = sceneDelegate.window else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        
        ImagesListService.shared.fetchPhotosNextPage()
        
        
    }
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        profileServise.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            switch result {
            case let .success(profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()
            case . failure(let error):
                print("Ошибка получения профиля: \(error)")
                break
                
            }
        }
    }
}

extension
SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let vc = navigationController.viewControllers.first as? AuthViewController
            else {
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                return
            }
            
            vc.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension
SplashViewController: AuthViewControlletDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true)
            
        switchToTabBarController()
   }
}

