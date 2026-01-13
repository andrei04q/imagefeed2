import UIKit

final class SingleImageViewController: UIViewController {
    
    
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!
    
    var photo: Photo? {
        didSet {
            guard isViewLoaded, let photo = photo else { return }
            loadImage(from: photo)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        imageView.image = image
        
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        scrollView.delegate = self
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit 
        
        if let photo = photo {
            loadImage(from: photo)
        }
//        guard let image else { return }
//        imageView.image = image
//        imageView.frame.size = image.size
//        rescaleAndCenterImageInScrollView(image: image)
    }
    
    private func loadImage(from photo: Photo) {
        guard let url = URL(string: photo.largeImageURL) else { return }
        
        imageView.kf.indicatorType = .activity
        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: url) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            switch result {
            case .success:
                self.rescaleAndCenterImageInScrollView()
            case .failure(let error):
                self.showError()
                print("Ошибка загрузки изображения: \(error)")
            }
        }
    }
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func didTapShareButton(_ sender: Any) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
        
    }
    
    private func showError() {
        guard let photo = photo else { return }
        
        let alertController = UIAlertController(
            title: "Что-то пошло не так. Попробовать еще раз?",
            message: nil,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(
            title: "Не надо",
            style: .cancel
        ) { _ in
            self.dismiss(animated: true)
        }
        
        let retryAction = UIAlertAction(
            title: "Повторить",
            style: .default
        ) { _ in
            self.loadImage(from: photo)
        }
         
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        present(alertController, animated: true)
    }
    
    
    private func rescaleAndCenterImageInScrollView() {
        guard let image = imageView.image else { return }
        
        imageView.frame.size = image.size
        
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        
        
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
    
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming( in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

