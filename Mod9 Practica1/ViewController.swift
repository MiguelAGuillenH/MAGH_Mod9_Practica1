//
//  ViewController.swift
//  Mod9 Practica1
//
//  Created by MAGH on 24/06/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    //UI Variables
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    //Internet Monitor
    var internetMonitor = InternetMonitor()
    
    //Audio Player
    var audioPlayer: AVAudioPlayer!
    var timer: Timer!
    var formatter: DateComponentsFormatter!

    //MARK: View Controller Events
    
    override func viewDidAppear(_ animated: Bool) {
        //Formatter setup
        formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        //Optional audio setup
        audioInit()
        
        //Download audio
        downloadAudio()
    }
    
    //MARK: UI Events
    
    @IBAction func playButtonTouched(_ sender: UIButton) {
        if (audioPlayer.isPlaying) {
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            audioPlayer.pause()
        } else {
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            audioPlayer.play()
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        audioPlayer.currentTime = TimeInterval(durationSlider.value)
    }
    
    //MARK: AudioPlayer delegate functions
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    //MARK: Custom functions
    
    func audioInit() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            showErrorAlert(message: "Error al inicializar audio.\n\(error.localizedDescription)", buttonTitle: "Reintentar") { buttonAction in
                self.audioInit()
            }
        }
    }
    
    func downloadAudio() {
        if internetMonitor.isConnected && internetMonitor.connType == "Wi-Fi" {
            let urlString = "http://janzelaznog.com/DDAM/iOS/imperial-march.mp3"
            if let url = URL(string: urlString) {
                activityIndicatorView.startAnimating()
                
                let request = URLRequest(url: url)
                let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
                let task = session.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
                        self.activityIndicatorView.stopAnimating()
                        
                        if error != nil {
                            self.showErrorAlert(message: "Ocurrió un error al descargar el audio.\n\(error!.localizedDescription)", buttonTitle: "Reintentar") { buttonAction in
                                self.downloadAudio()
                            }
                        } else if data == nil {
                            self.showErrorAlert(message: "Ocurrió un error al descargar el audio.", buttonTitle: "Reintentar") { buttonAction in
                                self.downloadAudio()
                            }
                        } else {
                            //Save audio file
                            do {
                                let libraryUrl = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                                let fileUrl = libraryUrl.appendingPathComponent(url.lastPathComponent)
                                if FileManager().fileExists(atPath: fileUrl.path) {
                                    try FileManager().removeItem(at: fileUrl)
                                }
                                try data!.write(to: fileUrl)
                                
                                //Set audio file for playing
                                self.setUpAudio(fileUrl)
                            } catch {
                                self.showErrorAlert(message: "Ocurrió un error al guardar el archivo.\n\(error.localizedDescription)", buttonTitle: "Reintentar") { buttonAction in
                                    self.downloadAudio()
                                }
                            }
                        }
                    }
                }
                task.resume()
            }
        } else {
            showErrorAlert(message: "Se requiere una conexión a Internet via Wi-Fi para continuar.", buttonTitle: "Reintentar") { buttonAction in
                self.downloadAudio()
            }
        }
    }
    
    func setUpAudio(_ fileUrl: URL) {
        do {
            print(fileUrl.absoluteString)
            audioPlayer = try AVAudioPlayer(contentsOf: fileUrl)
            audioPlayer.delegate = self
            durationSlider.maximumValue = Float(self.audioPlayer.duration)
            durationLabel.text = formatter.string(from: self.audioPlayer.duration)
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { tmr in
                //Cada segundo, actualizar el Slider de duración
                self.durationSlider.value = Float(self.audioPlayer.currentTime)
                self.currentLabel.text  = self.formatter.string(from: self.audioPlayer.currentTime)
            }
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playerView.isHidden = false
        } catch {
            showErrorAlert(message: "Ocurrió un error al cargar el audio para su reproducción.\n\(error.localizedDescription)", buttonTitle: "Reintentar") { buttonAction in
                self.downloadAudio()
            }
        }
    }
    
    func showErrorAlert(message: String, buttonTitle: String, buttonAction: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let ac1 = UIAlertAction(title: buttonTitle, style: .default, handler: buttonAction)
        alert.addAction(ac1)
        self.present(alert, animated: true)
    }
    
}

