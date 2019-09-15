//
//  ViewController.swift
//  FlowerRecognition
//
//  Created by Krishna Ajmeri on 9/12/19.
//  Copyright © 2019 Krishna Ajmeri. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var textLabel: UILabel!

	let wikipediaURL = "https://en.wikipedia.org/w/api.php"
	let imagePicker = UIImagePickerController()

	override func viewDidLoad() {
		super.viewDidLoad()

		imagePicker.delegate = self
		imagePicker.allowsEditing = false

		imagePicker.sourceType = .photoLibrary
		//imagePicker.sourceType = .camera
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		if let userImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {

			guard let ciImage = CIImage(image: userImage) else {
				fatalError("Could not convert image to CIImage")
			}

			detect(image: ciImage)

		}

		imagePicker.dismiss(animated: true, completion: nil)

	}

	func detect(image: CIImage) {

		guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
			fatalError("Loading CoreML Model failed")
		}

		let request = VNCoreMLRequest(model: model) { (request, error) in
			guard let classification = request.results?.first as? VNClassificationObservation else {
				fatalError("Model failed to process image")
			}

			self.navigationItem.title = classification.identifier.capitalized
			self.requestInfo(flowerName: classification.identifier)

		}

		let handler = VNImageRequestHandler(ciImage: image)

		do {
			try handler.perform([request])
		} catch {
			print(error)
		}
	}

	func requestInfo(flowerName: String) {

		let parameters : [String:String] = [

			"format" : "json",
			"action" : "query",
			"prop" : "extracts|pageimages",
			"exintro" : "",
			"explaintext" : "",
			"titles" : flowerName,
			"indexpageids" : "",
			"redirects" : "1",
			"pithumbsize" : "500"
		]

		Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON {
			(response) in
			if response.result.isSuccess {

				let flowerJSON : JSON = JSON(response.result.value!)

				let pageID = flowerJSON["query"]["pageids"][0].stringValue

				let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue

				let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue

				self.imageView.sd_setImage(with: URL(string: flowerImageURL))

				self.textLabel.text = flowerDescription
			}
		}
	}


	@IBAction func cameraTapped(_ sender: UIBarButtonItem) {
		
		present(imagePicker, animated: true, completion: nil)

	}


}
