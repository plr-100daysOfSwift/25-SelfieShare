//
//  ViewController.swift
//  SelfieShare
//
//  Created by Paul Richardson on 08/06/2021.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {

	var images = [UIImage]()
	var peerID = MCPeerID(displayName: UIDevice.current.name)
	var mcSession: MCSession?
	var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?

	let serviceType = "plr-selfieshare"

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Selfie Share"

		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))

		mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
		mcSession?.delegate = self

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
		let picker = UIImagePickerController()
		picker.allowsEditing = true
		picker.delegate = self
		present(picker, animated: true)
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		guard let image = info[.editedImage] as? UIImage else { return }
		dismiss(animated: true)
		images.insert(image, at: 0)
		collectionView.reloadData()

		guard let mcSession = mcSession else { return }
		if mcSession.connectedPeers.count > 0 {
			if let imageData = image.pngData() {
				do {
					try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
				} catch {
					let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
					ac.addAction(UIAlertAction(title: "OK", style: .default))
					present(ac, animated: true)
				}
			}
		}
	}

	@objc func showConnectionPrompt() {
		let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
		ac.addAction(UIAlertAction(title: "Start hosting", style: .default, handler: startHosting))
		ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
		ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(ac, animated: true)
	}

	func startHosting(action: UIAlertAction) {
		nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
		nearbyServiceAdvertiser?.startAdvertisingPeer()
		nearbyServiceAdvertiser?.delegate = self
	}

	func joinSession(action: UIAlertAction) {
		guard let mcSession = mcSession else { return }
		let mcBrowser = MCBrowserViewController(serviceType: serviceType, session: mcSession)
		mcBrowser.delegate = self
		present(mcBrowser, animated: true)
	}

	// MARK:- MCSession Delegate Methods

	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

	}

	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

	}

	func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

	}

	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		switch state {
		case .connected:
			print("Connected: \(peerID.displayName)")
		case .connecting:
			print("Connecting: \(peerID.displayName)")
		case .notConnected:
			DispatchQueue.main.async { [weak self] in
				let ac = UIAlertController(title: "\(peerID.displayName) has disconnected.", message: nil, preferredStyle: .alert)
				ac.addAction(UIAlertAction(title: "OK", style: .default))
				self?.present(ac, animated: true)
			}
		@unknown default:
			print("Unknown connection state: \(peerID.displayName)")
		}
	}

	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		DispatchQueue.main.async { [weak self] in
			if let image = UIImage(data: data) {
				self?.images.insert(image, at: 0)
				self?.collectionView.reloadData()
			}
		}
	}

	// MARK:- MCBrowser Delegate Methods

	func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
		dismiss(animated: true)
	}

	func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
		dismiss(animated: true)
	}

	// MARK:- MCNearbyServiceAdvertiser Delegate Methods

	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		invitationHandler(true, mcSession)
	}

	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		let ac = UIAlertController(title: "Hosting error", message: error.localizedDescription, preferredStyle: .alert)
		ac.addAction(UIAlertAction(title: "OK", style: .default))
		present(ac, animated: true)
	}

}
