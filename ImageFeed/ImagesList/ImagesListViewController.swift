import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
     
    private let showsSingleImageSegueIdentifier = "ShowSingleImage"
    private let pleceholderImage = UIImage(named: "stub")
    
    @IBOutlet private var tableView: UITableView!
    
    private var photos: [Photo] = []
    private let photoService = ImagesListService.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        subscribeToNotifications()
    }
    
    private func setupTableView() {
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
              tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
              tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
              tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
              tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
          ])
    }
    
    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewAnimated),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newPhotos = photoService.photos
        let newCount = newPhotos.count
        
        guard newCount > oldCount else {
            if newCount != oldCount {
                photos = newPhotos
                tableView.reloadData()
            }
            return
        }
        let indexPaths = (oldCount ..< newCount).map { IndexPath(row: $0, section: 0)}
        tableView.performBatchUpdates {
            self.photos = newPhotos
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        
        let photo = photos[indexPath.row]
        if let url = URL(string: photo.thumbImageURL) {
            imageListCell.cellImage.kf.indicatorType = .activity
            imageListCell.cellImage.kf.setImage(
                with: url,
                placeholder: pleceholderImage
            )
        } else {
            imageListCell.cellImage.image = pleceholderImage
        }
        
        if let createAt = photo.createdAt {
            imageListCell.dateLabel.text = DateFormatter.imageFeedDisplayDate.string(from: createAt)
        } else {
            imageListCell.dateLabel.text = "-"
        }
        imageListCell.setIsLiked(photo.isLiked)
        imageListCell.delegate = self
        
        return imageListCell
    }
}

extension ImagesListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "ShowSingleImage") as? SingleImageViewController else {
                return
            }
            vc.photo = photos[indexPath.row]
            present(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < photos.count else {
            return 300
        }
        
        let photo = photos[indexPath.row]
        guard let url = URL(string: photo.thumbImageURL) else { return 300 }
        
        if let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: url.absoluteString) {
            let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
            let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
            let imageWidth = image.size.width
            let scale = imageViewWidth / imageWidth
            let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
            return cellHeight
        } else {
            return 300
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            let lastRowIndex = photos.count - 1
            if indexPath.row == lastRowIndex {
                photoService.fetchPhotosNextPage()
            }
        }
}

extension ImagesListViewController: ImageListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        UIBlockingProgressHUD.show()
        photoService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { result in
            switch result {
            case .success:
                self.photos = self.photoService.photos
                cell.setIsLiked(self.photos[indexPath.row].isLiked)
                
                UIBlockingProgressHUD.dismiss()
                
            case .failure(let error):
                UIBlockingProgressHUD.dismiss()
                print("Ошибка лайка: \(error.localizedDescription)")
            }
        }
    }
}
