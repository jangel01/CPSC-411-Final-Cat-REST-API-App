//
//  ViewController.swift
//  CatAPIFinalProject
//
//  Created by Jason Angel on 11/20/23.
//

import UIKit

class CatSearchViewController: UIViewController {

    @IBOutlet var searchImageView: UIImageView!
    @IBOutlet var downvoteButton: UIButton!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var nameInput: UITextField!
    @IBOutlet var amountInput: UITextField!
    
    var catAPIService: CatAPIService!
    var catRepo: CatRepo!
    var currentImageUrl: URL?
    var currentImageData: Data?
    
    var catSearchImages: [SearchImagesData]? = nil
    var currentImageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.catAPIService = CatAPIService()
        self.catRepo = CatRepo {
            (initResult) in
        }
        
        self.fetchCatImages()
    }
    
    func updateSearchImageView(for image: SearchImagesData) {
        self.currentImageUrl = image.url
        self.catAPIService.downloadSearchImage(for: image) {
            (imageResult) in
        
            switch imageResult {
            case let .success(image):
                print("Successfully downloaded search image: \(image)")
                self.searchImageView.image = image
                
                // try converting to jpg first
                if let imageData = image.jpegData(compressionQuality: 1.0) {
                    self.currentImageData = imageData
                }
                // try converting to png
                else if let imageData = image.pngData() {
                    self.currentImageData = imageData
                } else {
                    print("Error grabbing current image data")
                }
            case let .failure(error):
                print("Error downloading image: \(error)")
            }
        }
    }
    
    func fetchCatImages() {
        self.catAPIService.getSearchImages {
            (getSearchResult) in
            
            switch getSearchResult {
            case let .success(images):
                print("Successfully found \(images.count) cat images!")
                self.catSearchImages = images
                self.currentImageIndex = 0
                
                if !images.isEmpty {
                    self.updateSearchImageView(for: images.first!)
                    self.toggleVoteButtons(true)
                }
            case let .failure(error):
                print("Error fetching random cat images: \(error)")
            }
        }
    }
    
    @IBAction func prevButtonTapped(_ btn: UIButton) {
        if let catSearchImages = self.catSearchImages {
            if currentImageIndex > 0 {
                self.currentImageIndex -= 1
            } else {
                currentImageIndex = catSearchImages.count - 1
            }
                        
            updateSearchImageView(for: catSearchImages[self.currentImageIndex])
            self.toggleVoteButtons(true)
        } else {
            print("error: there are no images to traverse")
        }
    }
    
    @IBAction func nextButtonTapped(_ btn: UIButton) {
        if let catSearchImages = self.catSearchImages {
            if self.currentImageIndex < catSearchImages.count - 1 {
                self.currentImageIndex += 1
            } else {
                self.currentImageIndex = 0
            }

            updateSearchImageView(for: catSearchImages[self.currentImageIndex])
            self.toggleVoteButtons(true)
        } else {
            print("error: there are no images to traverse")
        }
    }
    
    @IBAction func rerollButtonTapped(_ btn: UIButton) {
        fetchCatImages()
    }
    
    @IBAction func upvoteButtonTapped(_ btn: UIButton) {
        if let catSearchImages = self.catSearchImages {
            self.catAPIService.voteOnImage(imageId: catSearchImages[currentImageIndex].id, value: 1) {
                (voteResult) in
                
                switch voteResult {
                case let .success(result):
                    print("upvoted cat image! \(result.imageId), status: \(result.message)")
                    self.toggleVoteButtons(false)
                    
                    let alert = UIAlertController(title: "Vote recorded!", message: "You have upvoted the image", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                case let .failure(error):
                    print("Failed to upvote image: \(error)")
                }
            }
        } else {
            print("error: there is no image to upvote")
        }
    }
    
    @IBAction func downvoteButtonTapped(_ btn: UIButton) {
        if let catSearchImages = self.catSearchImages {
            self.catAPIService.voteOnImage(imageId: catSearchImages[currentImageIndex].id, value: -1) {
                (voteResult) in
                
                switch voteResult {
                case let .success(result):
                    print("downvoted cat image! \(result.imageId), status: \(result.message)")
                    self.toggleVoteButtons(false)
                    
                    let alert = UIAlertController(title: "Vote recorded!", message: "You have downvoted the image", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                case let .failure(error):
                    print("Failed to downvote image: \(error)")
                }
            }
        } else {
            print("error: there is no image to downvote")
        }
    }
    
    func toggleVoteButtons(_ btnState: Bool) {
        self.upvoteButton.isEnabled = btnState
        self.downvoteButton.isEnabled = btnState
    }
    
    private func viewToCat(cat: Cat) -> Bool {
        
        if let name = self.nameInput.text, let amount = self.amountInput.text {
            cat.name = name
            cat.amount = NSDecimalNumber(string: amount)
            
            if let urlAsString = currentImageUrl?.absoluteString, let data = self.currentImageData {
                let url = URL(string: urlAsString)
                if let urlSafe = url {
                    let filename = urlSafe.lastPathComponent
                    cat.imgPath = urlAsString
                    CatPersistence.saveFileToUserFolder(fileName: filename, data: data)
                    
                    let alert = UIAlertController(title: "Cat saved!", message: "You have saved the cat image and information", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("error: couldn't save to user folder -- url is innvalid")
                }
            }
            return true
        } else {
            print("Unable to parse Cat from views; one or more was blank or invalid, or there is an issue with the image url")
        }
        return false
    }
    
    @IBAction func saveButtonTapped(_ btn: UIButton) {
        let cat = self.catRepo.makeCat()
        if (self.viewToCat(cat: cat)) {
            self.catRepo.saveCat(cat: cat) {
                (saveResult) in
            }
        }
    }
}

