//
//  Upstream.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/03/18.
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

public enum Upstream {
    public struct Event {
        public let payload: [String: AnyHashable]
        public let header: Header
        public let contextPayload: ContextPayload
        
        public init(payload: [String: AnyHashable], header: Header, contextPayload: ContextPayload) {
            self.payload = payload
            self.header = header
            self.contextPayload = contextPayload
        }
    }

    public struct Attachment {
        public let header: Header
        public let content: Data
        public let seq: Int32
        public let isEnd: Bool
        public let type: String
        
        public init(header: Header, content: Data, type: String, seq: Int32, isEnd: Bool) {
            self.header = header
            self.content = content
            self.type = type
            self.seq = seq
            self.isEnd = isEnd
        }
    }

    public struct Header {
        public let namespace: String
        public let name: String
        public let version: String
        public let dialogRequestId: String
        public let messageId: String
        
        public init(namespace: String, name: String, version: String, dialogRequestId: String, messageId: String) {
            self.namespace = namespace
            self.name = name
            self.version = version
            self.dialogRequestId = dialogRequestId
            self.messageId = messageId
        }
    }
}

extension Upstream.Event {
    var headerString: String {
        let headerDictionary = ["namespace": header.namespace,
                                "name": header.name,
                                "dialogRequestId": header.dialogRequestId,
                                "messageId": header.messageId,
                                "version": header.version]

        guard let data = try? JSONSerialization.data(withJSONObject: headerDictionary, options: []),
            let headerString = String(data: data, encoding: .utf8) else {
                return ""
        }
        
        return headerString
    }
    
    var payloadString: String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
            let payloadString = String(data: data, encoding: .utf8) else {
                return ""
        }
        
        return payloadString
    }
    
    var contextString: String {
        let supportedInterfaces = contextPayload.supportedInterfaces.reduce(
            into: [String: AnyHashable]()
        ) { result, context in
            result[context.name] = context.payload
        }
        let client = contextPayload.client.reduce(
            into: [String: AnyHashable]()
        ) { result, context in
            result[context.name] = context.payload
        }
        
        let contextDict: [String: AnyHashable] = [
            "supportedInterfaces": supportedInterfaces,
            "client": client
        ]
        
        guard
            let data = try? JSONSerialization.data(withJSONObject: contextDict.compactMapValues { $0 }, options: []),
            let contextString = String(data: data, encoding: .utf8) else {
                return ""
        }
        
        return contextString
    }
}