//
//  ViewController.swift
//  SelfieShare
//
//  Created by Paul Richardson on 08/06/2021.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UINavigationControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {

	var bonmots = [String]()
	var peerID = MCPeerID(displayName: UIDevice.current.name)
	var mcSession: MCSession?
	var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?

	let serviceType = "plr-selfieshare"

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Bon Mot Share"

		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(addBonMot))

		mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
		mcSession?.delegate = self

	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return bonmots.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextView", for: indexPath)
		if let textView = cell.viewWithTag(1000) as? UITextView {
			textView.text = bonmots[indexPath.item]
		}
		return cell
	}

	@objc func addBonMot() {
		let ac = UIAlertController(title: "Add a Bon Mot", message: nil, preferredStyle: .alert)
		ac.addTextField()
		ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak ac] _ in
			if let text = ac?.textFields?[0].text {
				self?.bonmots.append(text)
				self?.collectionView.reloadData()
				self?.sendToPeers(text)
			}
		}))
		ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(ac, animated: true)
	}

	fileprivate func sendToPeers(_ text: String) {
		guard let mcSession = self.mcSession else { return }
		if mcSession.connectedPeers.count > 0 {
			let textData = Data(text.utf8)
			do {
				try mcSession.send(textData, toPeers: mcSession.connectedPeers, with: .reliable)
			} catch {
				let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
				ac.addAction(UIAlertAction(title: "OK", style: .default))
				present(ac, animated: true)
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
			alertStateChange(peerID, state: state)
		case .connecting:
			print("Connecting: \(peerID.displayName)")
		case .notConnected:
			alertStateChange(peerID, state: state)
		@unknown default:
			print("Unknown connection state: \(peerID.displayName)")
		}
	}

	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		DispatchQueue.main.async { [weak self] in
			let text = String(decoding: data, as: UTF8.self)
			self?.bonmots.insert(text, at: 0)
			self?.collectionView.reloadData()
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

	// MARK:- Private Methods

	fileprivate func alertStateChange(_ peerID: MCPeerID, state: MCSessionState) {
		guard state == .connected || state == .notConnected else { return }
		let stateDescription = state == .connected ? "connected" : "disconnected"

		DispatchQueue.main.async { [weak self] in
			let ac = UIAlertController(title: "\(peerID.displayName) has \(stateDescription).", message: nil, preferredStyle: .alert)
			ac.addAction(UIAlertAction(title: "OK", style: .default))
			self?.present(ac, animated: true)
		}
	}

}
