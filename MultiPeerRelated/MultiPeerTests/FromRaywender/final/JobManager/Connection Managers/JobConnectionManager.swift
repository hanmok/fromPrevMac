/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import MultipeerConnectivity

class JobConnectionManager: NSObject, ObservableObject {
  typealias JobReceivedHandler = (JobModel) -> Void
  private static let service = "jobmanager-jobs"

  @Published var employees: [MCPeerID] = []

  private var session: MCSession
  private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
  private var nearbyServiceBrowser: MCNearbyServiceBrowser
  private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser
  private let jobReceivedHandler: JobReceivedHandler?

  private var jobToSend: JobModel?
  private var peerInvitee: MCPeerID?

  init(_ jobReceivedHandler: JobReceivedHandler? = nil) {
    session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
    nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
      peer: myPeerId,
      discoveryInfo: nil,
      serviceType: JobConnectionManager.service)
    nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: JobConnectionManager.service)
    self.jobReceivedHandler = jobReceivedHandler
    super.init()
    session.delegate = self
    nearbyServiceAdvertiser.delegate = self
    nearbyServiceBrowser.delegate = self
  }

  func startBrowsing() {
    nearbyServiceBrowser.startBrowsingForPeers()
  }

  func stopBrowsing() {
    nearbyServiceBrowser.stopBrowsingForPeers()
  }

  var isReceivingJobs: Bool = false {
    didSet {
      if isReceivingJobs {
        nearbyServiceAdvertiser.startAdvertisingPeer()
      } else {
        nearbyServiceAdvertiser.stopAdvertisingPeer()
      }
    }
  }

  func invitePeer(_ peerID: MCPeerID, to job: JobModel) {
    jobToSend = job
    let context = job.name.data(using: .utf8)
    nearbyServiceBrowser.invitePeer(peerID, to: session, withContext: context, timeout: TimeInterval(120))
  }

  private func send(_ job: JobModel, to peer: MCPeerID) {
    do {
      let data = try JSONEncoder().encode(job)
      try session.send(data, toPeers: [peer], with: .reliable)
    } catch {
      print(error.localizedDescription)
    }
  }
}

extension JobConnectionManager: MCNearbyServiceAdvertiserDelegate {
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    guard
      let window = UIApplication.shared.windows.first,
      let context = context,
      let jobName = String(data: context, encoding: .utf8)
    else { return }

    let title = "Accept \(peerID.displayName)'s Job"
    let message = "Would you like to accept: \(jobName)"
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
      invitationHandler(true, self.session)
    })
    window.rootViewController?.present(alertController, animated: true)
  }
}

extension JobConnectionManager: MCNearbyServiceBrowserDelegate {
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
    if !employees.contains(peerID) {
      employees.append(peerID)
    }
  }

  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    guard let index = employees.firstIndex(of: peerID) else { return }
    employees.remove(at: index)
  }
}

extension JobConnectionManager: MCSessionDelegate {
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected:
      guard let jobToSend = jobToSend else { return }
      send(jobToSend, to: peerID)
    case .notConnected:
      print("Not connected: \(peerID.displayName)")
    case .connecting:
      print("Connecting to: \(peerID.displayName)")
    @unknown default:
      print("Unknown state: \(state)")
    }
  }

  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let job = try? JSONDecoder().decode(JobModel.self, from: data) else { return }
    DispatchQueue.main.async {
      self.jobReceivedHandler?(job)
    }
  }

  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
