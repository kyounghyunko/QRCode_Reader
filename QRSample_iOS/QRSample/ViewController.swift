//
//  ViewController.swift
//  QRSample
//
//  Created by ko on 2019/02/18.
//  Copyright © 2019年 ko. All rights reserved.
//

import UIKit
import AVFoundation

// 前提として、info.plistにカメラ利用許可を入れる。

final class ViewController: UIViewController {
    
    // start/stopのためにプロパティ変数として宣言しておく
    private let session = AVCaptureSession()
    
    // IBOutlet
    @IBOutlet private weak var QRCodeInfoView: UIView! {
        didSet {
            self.QRCodeInfoView.layer.cornerRadius = self.QRCodeInfoView.frame.height / 2
        }
    }
    
    // MARK: - LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // カメラやマイクのデバイスそのものを管理するオブジェクトを生成（ここではワイドアングルカメラ・ビデオ・背面カメラを指定）
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: .video,
                                                                position: .back)
        
        // ワイドアングルカメラ・ビデオ・背面カメラに該当するデバイスを取得
        let devices = discoverySession.devices
        
        //　該当するデバイスのうち最初に取得したものを利用する
        if let backCamera = devices.first {
            do {
                // QRコードの読み取りに背面カメラの映像を利用するための設定
                let deviceInput = try AVCaptureDeviceInput(device: backCamera)
                
                if self.session.canAddInput(deviceInput) {
                    self.session.addInput(deviceInput)
                    
                    // 背面カメラの映像からQRコードを検出するための設定
                    let metadataOutput = AVCaptureMetadataOutput()
                    
                    if self.session.canAddOutput(metadataOutput) {
                        self.session.addOutput(metadataOutput)
                        
                        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = [.qr]
                        
                        // 背面カメラの映像を画面に表示するためのレイヤーを生成
                        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                        previewLayer.frame = self.view.frame
                        previewLayer.videoGravity = .resizeAspectFill
                        self.view.layer.insertSublayer(previewLayer, at: 0)
                        
                        // 読み取り開始
                        self.session.startRunning()
                    }
                }
            } catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }
    
    // MARK: - PrivateMethod
    
    private func startSession() {
        if !self.session.isRunning {
            self.session.startRunning()
        }
    }
    
    private func stopSession() {
        if self.session.isRunning {
            self.session.stopRunning()
        }
    }

}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    /// AVCaptureが認識した時
    ///
    /// - Parameters:
    ///   - output: AVCaptureMetadataOutput
    ///   - metadataObjects: [AVMetadataObject]
    ///   - connection: AVCaptureConnection
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataMachineReadableCodeObjects = metadataObjects as? [AVMetadataMachineReadableCodeObject] else { return }
        
        // 読み取り可能データの中でQRのみにfilterし、取得文字列が存在するもののみ読み取る。
        if let content = metadataMachineReadableCodeObjects.filter({ $0.type == .qr }).compactMap({ $0.stringValue }).first {
            
            // 一度止めないと映像内にQRが写っている間は何度も呼ばれてしまう。
            self.stopSession()
            
            let alert = UIAlertController(title: "Result",
                                          message: content,
                                          preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.startSession()
            }
            
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
