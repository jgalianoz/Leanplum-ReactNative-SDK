//
//  Leanplum.swift
//  Leanplum
//
//  Created by Alik . Risco on 30.01.20.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import Leanplum

@objc(RNLeanplum)
class RNLeanplum: RCTEventEmitter {
    
    var variables = [String: LPVar]()
    let undefinedVariableErrorMessage = "Undefined Variable"
    let undefinedVariableError = NSError(domain: "Undefined Variable", code: 404)
    var onVariableChangedListenerName = "onVariableChanged"
    var onVariablesChangedListenerName = "onVariablesChanged"
    var allSupportedEvents: [String] = []
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    override func supportedEvents() -> [String]! {
        return self.allSupportedEvents
    }
    
    @objc
    func setListenersNames(_ onVariableChangedListenerName: String, onVariablesChangedListenerName: String) {
        self.onVariableChangedListenerName = onVariableChangedListenerName;
        self.onVariablesChangedListenerName = onVariablesChangedListenerName;
    }
    
    @objc
    func setAppIdForDevelopmentMode(_ appId: String, accessKey: String) -> Void {
        Leanplum.setAppId(appId, withDevelopmentKey: accessKey)
    }
    
    @objc
    func setAppIdForProductionMode(_ appId: String, accessKey: String) -> Void {
        Leanplum.setAppId(appId, withProductionKey: accessKey)
    }
    
    @objc
    func setDeviceId(_ id: String) -> Void {
        Leanplum.setDeviceId(id)
    }
    
    @objc
    func setUserId(_ id: String) -> Void {
        Leanplum.setUserId(id)
    }
    
    @objc
    func setUserAttributes(_ attributes: NSDictionary) -> Void {
        let attributesDict = attributes as! Dictionary<String,Any>
        Leanplum.setUserAttributes(attributesDict)
    }
    
    @objc
    func start() -> Void {
        Leanplum.start()
    }
    
    @objc
    func track(_ event: String, params: NSDictionary) -> Void {
        let withParameters = params as! Dictionary<String,Any>
        Leanplum.track(event, withParameters: withParameters)
    }
    
    @objc
    func trackPurchase(_ purchaseEvent: String, value: Double, currencyCode: String, purchaseParams: NSDictionary) -> Void {
        let parameters = purchaseParams as! Dictionary<String,Any>
        Leanplum.trackPurchase(purchaseEvent, withValue: value, andCurrencyCode: currencyCode, andParameters: parameters)
    }
    
    @objc
    func disableLocationCollection() -> Void {
        Leanplum.disableLocationCollection()
    }
    
    @objc
    func setDeviceLocation(_ latitude: Double, longitude: Double, type: Int) -> Void {
        let accuracyType = LPLocationAccuracyType(rawValue: UInt32(type))
        Leanplum.setDeviceLocationWithLatitude(latitude, longitude: longitude, type: accuracyType)
    }
    
    @objc
    func forceContentUpdate() -> Void {
        Leanplum.forceContentUpdate();
    }
    
    
    @objc
    func setVariables(_ variables: NSDictionary) -> Void {
        guard let variablesDict = variables as? Dictionary<String, Any> else {
            return
        }
        for (key, value) in variablesDict {
            if let lpVar = LeanplumTypeUtils.createVar(key: key, value: value) {
                self.variables[key] = lpVar;
            }
        }
    }
    
    @objc
    func getVariable(_ variableName: String, resolver resolve: RCTPromiseResolveBlock,
                     rejecter reject: RCTPromiseRejectBlock
    ) {
        if let lpVar = self.variables[variableName] {
            resolve(lpVar.value)
        } else {
            reject(self.undefinedVariableErrorMessage, "\(undefinedVariableErrorMessage): '\(variableName)'", self.undefinedVariableError)
        }
    }
    
    @objc
    func getVariables(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        resolve(self.getVariablesValues())
    }
    
    
    func getVariablesValues() -> [String: Any] {
        var allVariables = [String: Any]()
        for (key, value) in self.variables {
            if(value.kind == "file") {
                continue
            }
            allVariables[key] = value.value
        }
        return allVariables
    }
    
    @objc
    func onStartResponse(_ callback: @escaping RCTResponseSenderBlock) {
        Leanplum.onStartResponse { (success:Bool) in
            callback([success])
        }
    }
    
    @objc
    func onValueChanged(_ variableName: String) {
        if let lpVar = self.variables[variableName] {
            let listenerName = "\(self.onVariableChangedListenerName).\(variableName)"
            self.allSupportedEvents.append(listenerName)
            lpVar.onValueChanged {
                self.sendEvent(withName: listenerName, body: lpVar.value)
            }
        }
    }
    
    @objc
    func onVariablesChanged() {
        self.allSupportedEvents.append(self.onVariablesChangedListenerName)
        Leanplum.onVariablesChanged {
            self.sendEvent(withName: self.onVariablesChangedListenerName, body: self.getVariablesValues())
        }
    }
    
    @objc
    func setVariableAsset(_ name: String, filename: String) -> Void {
        self.allSupportedEvents.append(name)
        let lpVar = LPVar.define(name, withFile: filename)
        self.variables[name] = lpVar
        lpVar?.onFileReady({
            self.sendEvent(withName: name, body: lpVar?.fileValue())
        })
    }
    
    @objc
    func getVariableAsset(_ name: String, resolver resolve: RCTPromiseResolveBlock,
                          rejecter reject: RCTPromiseRejectBlock
    ) {
        if let lpVar = self.variables[name] {
            resolve(lpVar.fileValue())
        } else {
            reject(self.undefinedVariableErrorMessage, "\(undefinedVariableErrorMessage): '\(name)'", self.undefinedVariableError)
        }
    }
    
    @objc
    func pauseState() {
        Leanplum.pauseState();
    }
    
    @objc
    func resumeState() {
        Leanplum.resumeState();
    }
    
    @objc
    func trackAllAppScreens() {
        Leanplum.trackAllAppScreens();
    }
    
    @objc
    func advanceTo(_ state: String) {
        Leanplum.advance(to: state)
    }
    
    @objc
    func advanceToWithInfo(_ state: String, info: String) {
        Leanplum.advance(to: state, withInfo: info)
    }
    
    @objc
    func advanceToWithParams(_ state: String, params: NSDictionary) {
        guard let paramsDict = params as? Dictionary<String, Any> else {
            return
        }
        Leanplum.advance(to: state, withParameters: paramsDict)
    }
    
    
    @objc
    func advanceToWithInfoAndParams(_ state: String, info: String, params: NSDictionary) {
        guard let paramsDict = params as? Dictionary<String, Any> else {
            return
        }
        Leanplum.advance(to: state, withInfo: info, andParameters: paramsDict)
    }
    
    @objc
    func getInbox(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        resolve(self.getInboxValue())
    }
    
    func getInboxValue() -> [String: Any] {
        var inbox = [String: Any]()
        let leanplumInbox = Leanplum.inbox()
        inbox["count"] = leanplumInbox?.count()
        inbox["unreadCount"] = leanplumInbox?.unreadCount
        inbox["messagesIds"] = leanplumInbox?.messagesIds()
        inbox["allMessages"] = LeanplumTypeUtils.leanplumMessagesToArray(leanplumInbox?.allMessages() as! [LPInboxMessage])
        inbox["unreadMessages"] = LeanplumTypeUtils.leanplumMessagesToArray(leanplumInbox?.unreadMessages() as! [LPInboxMessage])
        return inbox
    }
    
    @objc
    func messageForId(_ messageId: String, resolver resolve: RCTPromiseResolveBlock,
                      rejecter reject: RCTPromiseRejectBlock
    ) {
        if let message = Leanplum.inbox()?.message(forId: messageId) {
            resolve(LeanplumTypeUtils.leanplumMessageToDict(message))
        } else {
            resolve(nil)
        }
    }
    
    @objc
    func read(_ messageId: String) -> Void {
        let message = Leanplum.inbox()?.message(forId: messageId)
        message?.read()
    }
    
    
    @objc
    func remove(_ messageId: String) -> Void {
        let message = Leanplum.inbox()?.message(forId: messageId)
        message?.remove()
    }
    
    @objc
    func onInboxChanged(_ listener: String) -> Void {
        self.allSupportedEvents.append(listener)
        Leanplum.inbox()?.onChanged({
            self.sendEvent(withName: listener, body: self.getInboxValue())
        })
    }

    @objc
    func onInboxForceContentUpdate(_ listener: String) -> Void {
        self.allSupportedEvents.append(listener)
        Leanplum.inbox()?.onForceContentUpdate({ (Bool) in
            self.sendEvent(withName: listener, body: self.getInboxValue())
        })
    }
}
