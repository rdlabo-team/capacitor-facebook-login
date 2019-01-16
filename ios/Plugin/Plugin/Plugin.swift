import Foundation
import Capacitor
import FBSDKCoreKit
import FBSDKLoginKit

@objc(FacebookLogin)
public class FacebookLogin: CAPPlugin {
    private let loginManager = FBSDKLoginManager()
    
    private let dateFormatter = ISO8601DateFormatter()
    
    override public func load() {
        if #available(iOS 11, *) {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
        }
        
    }

    private func dateToJS(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    @objc func login(_ call: CAPPluginCall) {
        guard let permissions = call.getArray("permissions", String.self) else {
            call.error("Missing permissions argument")
            return;
        }
        
        print(permissions)
        DispatchQueue.main.async {
            self.loginManager.logOut()
            self.loginManager.logIn(withReadPermissions: permissions, from: self.bridge.viewController, handler: { (loginResult, error) in
                if error != nil {
                    print(error)
                    call.reject("LoginManager.logIn failed", error)
                } else {
                    print(loginResult)
                    return self.getCurrentAccessToken(call)
                }
            })
        }
    }
        
    @objc func logout(_ call: CAPPluginCall) {
        loginManager.logOut()
        
        call.success()
    }
    
    private func accessTokenToJson(_ accessToken: FBSDKAccessToken) -> [String: Any?] {
        return [
            "applicationId": accessToken.appID,
            /*declinedPermissions: accessToken.declinedPermissions,*/
            "expires": dateToJS(accessToken.expirationDate),
            "lastRefresh": dateToJS(accessToken.refreshDate),
            /*permissions: accessToken.grantedPermissions,*/
            "token": accessToken.tokenString,
            "userId": accessToken.userID
        ]
    }
    
    @objc func getCurrentAccessToken(_ call: CAPPluginCall) {
        guard let accessToken = FBSDKAccessToken.current() else {
            call.success()
            return
        }
        
        call.success([ "accessToken": accessTokenToJson(accessToken) ])
    }
}
