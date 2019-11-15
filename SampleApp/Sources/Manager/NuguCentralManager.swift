//
//  NuguCentralManager.swift
//  SampleApp-iOS
//
//  Created by yonghoonKwon on 25/07/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import AVFoundation

import NuguInterface
import NuguClientKit
import KeenSense
import JadeMarble

final class NuguCentralManager {
    static let shared = NuguCentralManager()
    let client = NuguClient.default
    lazy private(set) var displayPlayerController = NuguDisplayPlayerController(client: client)
    
    private init() {
        client.focusManager.delegate = self
        client.authorizationManager.add(stateDelegate: self)
        client.contextManager.add(provideContextDelegate: self)
        
        if let epdFile = Bundle(for: type(of: self)).url(forResource: "skt_epd_model", withExtension: "raw") {
            client.endPointDetector?.epdFile = epdFile
        }
        
        /// Set Last WakeUp Keyword
        /// If you don't want to use saved wakeup-word, don't need to be implemented
        setWakeUpWord(rawValue: UserDefaults.Standard.wakeUpWord)
    }
}

// MARK: - Internal

extension NuguCentralManager {
    func enable(accessToken: String) {
        client.accessToken = accessToken
        client.networkManager.connect()
    }
    
    func disable() {
        client.focusManager.stopForegroundActivity()
        client.networkManager.disconnect()
        client.accessToken = nil
        client.inputProvider?.stop()
    }
}

// MARK: - Internal (ASR)

extension NuguCentralManager {
    func startRecognize(completion: ((Result<Void, Error>) -> Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] isGranted in
            guard let self = self else { return }
            let result = Result<Void, Error>(catching: {
                guard isGranted else { throw SampleAppError.recordPermissionError }
                self.client.asrAgent?.startRecognition()
            })
            completion?(result)
        }
    }
    
    func stopRecognize() {
        client.asrAgent?.stopRecognition()
    }
    
    func cancelRecognize() {
        client.asrAgent?.stopRecognition()
        
        client.focusManager.stopForegroundActivity()
    }
}

// MARK: - Internal (WakeUpDetector)

extension NuguCentralManager: ContextInfoDelegate {
    func contextInfoRequestContext() -> ContextInfo? {
        guard let keyWord = KeyWord(rawValue: UserDefaults.Standard.wakeUpWord) else {
            return nil
        }

        return ContextInfo(contextType: .client, name: "wakeupWord", payload: keyWord.description)
    }
    
    func startWakeUpDetector(completion: ((Result<Void, Error>) -> Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] isGranted in
            guard let self = self else { return }
            let result = Result<Void, Error>(catching: {
                guard isGranted else { throw SampleAppError.recordPermissionError }
                self.client.wakeUpDetector?.start()
            })
            completion?(result)
        }
    }
    
    func stopWakeUpDetector() {
        client.wakeUpDetector?.stop()
    }
    
    func setWakeUpWord(rawValue wakeUpWord: Int) {
        switch wakeUpWord {
        case KeyWord.aria.rawValue:
            if let netFile = Bundle.main.url(forResource: "skt_trigger_am_aria", withExtension: "raw"),
                let searchFile = Bundle.main.url(forResource: "skt_trigger_search_aria", withExtension: "raw") {
                client.wakeUpDetector?.netFile = netFile
                client.wakeUpDetector?.searchFile = searchFile
            }
        case KeyWord.tinkerbell.rawValue:
            if let netFile = Bundle.main.url(forResource: "skt_trigger_am_tinkerbell", withExtension: "raw"),
                let searchFile = Bundle.main.url(forResource: "skt_trigger_search_tinkerbell", withExtension: "raw") {
                client.wakeUpDetector?.netFile = netFile
                client.wakeUpDetector?.searchFile = searchFile
            }
        default:
            return
        }
    }
}

// MARK: - Internal (AudioSession)

extension NuguCentralManager {
    @discardableResult func setAudioSession() -> Bool {
        guard AVAudioSession.sharedInstance().category != .playAndRecord else {
            return true
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            return true
        } catch {
            log.debug("setCategory failed: \(error)")
            return false
        }
    }
}

// MARK: - AuthorizationStateDelegate

extension NuguCentralManager: AuthorizationStateDelegate {
    func authorizationStateDidChange(_ state: AuthorizationState) {
        switch state {
        case .error(let authorizationError):
            switch authorizationError {
            case .authorizationFailed:
                // TODO: - refresh token logic
                break
            default: break
            }
        default: break
        }
    }
}

// MARK: - FocusDelegate

extension NuguCentralManager: FocusDelegate {
    func focusShouldAcquire(channel: FocusChannelConfigurable) -> Bool {
        return setAudioSession()
    }
    
    func focusDidChange(channel: FocusChannelConfigurable, focusState: FocusState) {}
}
