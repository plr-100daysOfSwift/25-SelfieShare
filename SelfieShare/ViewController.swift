//
//  ViewController.swift
//  SelfieShare
//
//  Created by Paul Richardson on 08/06/2021.
//

import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	var images = [UIImage]()

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Selfie Share"

		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))

	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return images.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
		if let imageView = cell.viewWithTag(1000) as? UIImageView {
			imageView.image = images[indexPath.item]
		}
		return cell
	}

	@objc func importPicture() {

	}
}

