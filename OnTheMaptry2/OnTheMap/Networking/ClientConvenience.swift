//
//  ClientConvenience.swift
//  on the map
//
//  Created by fatoom on 10/10/1440 AH.
//  Copyright © 1440 Udacity. All rights reserved.
//

import Foundation

extension Client {
    
    /// Authenticate a user using the given credentials.
    
    func authenticateWith(userEmail: String, andPassword: String, completionHandlerForAuth: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        let jsonBody = "{\"udacity\": {\"username\": \"\(userEmail)\", \"password\": \"\(andPassword)\"}}"
        _ = taskForPOSTMethod(Constants.Udacity.Authentication, parameters: [:], jsonBody: jsonBody, completionHandlerForPOST: { (data, error) in
            if let error = error {
                print(error)
                completionHandlerForAuth(false, error.localizedDescription)
            } else {
                
                let userSessionData = self.parseUserSession(data: data)
                if let sessionData = userSessionData.0 {
                    guard let account = sessionData.account, account.registered == true else {
                        completionHandlerForAuth(false, "Login Failed, user not registered.")
                        return
                    }
                    guard let userSession = sessionData.session else {
                        completionHandlerForAuth(false, "Login Failed, no session to the user credentials provided.")
                        return
                    }
                    self.userKey = account.key
                    self.sessionID = userSession.id
                    completionHandlerForAuth(true, nil)
                } else {
                    completionHandlerForAuth(false, userSessionData.1!.localizedDescription)
                    self.sessionID = nil
                }
            }
        })
    }
    
    /// Ends the current user session.
    ///
    /// - Parameter completionHandlerForLogout: returns **true** in case the logout function was executed properly or **false** and the given error.
    func logout(completionHandlerForLogout: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        _ = taskForDeleteMethod(Constants.Udacity.Authentication, parameters: [:], completionHandlerForDELETE: { (data, error) in
            if let error = error {
                print(error)
                completionHandlerForLogout(false, error)
            } else {
                let sessionData = self.parseSession(data: data)
                if let _ = sessionData.0 {
                    self.userKey = ""
                    self.sessionID = ""
                    completionHandlerForLogout(true, nil)
                } else {
                    completionHandlerForLogout(false, sessionData.1!)
                }
            }
        })
    }
    
    
    func studentInfo(completionHandler: @escaping (_ result: StudentInfo?, _ error: NSError?) -> Void) {
        let url = Constants.Udacity.Users + "/\(userKey)"
        _ = taskForGETMethod(url, parameters: [:], completionHandlerForGET: { (data, error) in
            if let error = error {
                print(error)
                completionHandler(nil, error)
            } else {
                let response = self.parseStudentInfo(data: data)
                if let info = response.0 {
                    completionHandler(info, nil)
                } else {
                    completionHandler(nil, response.1)
                }
            }
        })
    }
    
    
    func studentsInformation(completionHandler: @escaping (_ result: [StudentInformation]?, _ error: NSError?) -> Void) {
        let params =  [Constants.ParseParameterKeys.Limit:Constants.ParameterValues.Limit,Constants.ParseParameterKeys.Order:Constants.ParameterValues.Order]
        
        _ = taskForGETMethod(Constants.Udacity.StudentLocation, parameters: params as [String : AnyObject], apiType: .parse) { (data, error) in
            if let error = error {
                print(error)
                completionHandler(nil, error)
            } else {
                if let data = data {
                    self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: { (jsonDoc, error) in
                        var students = [StudentInformation]()
                        if let results = jsonDoc?[Constants.ParseJSONResponseKeys.Results] as? [[String: AnyObject]] {
                            for doc in results {
                                students.append(StudentInformation(doc))
                            }
                            completionHandler(students, nil)
                            return
                        }
                        let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
                        completionHandler(students, NSError(domain: "studentsInformation", code: 1, userInfo: userInfo))
                    })
                }
            }
        }
    }
    
    func studentInformation(completionHandler: @escaping (_ result: StudentInformation?, _ error: NSError?) -> Void) {
        let params = [Constants.ParseParameterKeys.Where: "{\"uniqueKey\":\"\(userKey)\"}" as AnyObject]
        _ = taskForGETMethod(Constants.Udacity.StudentLocation, parameters: params, apiType: .parse) { (data, error) in
            if let error = error {
                print(error)
                completionHandler(nil, error)
            } else {
                if let data = data {
                    self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: { (jsonDoc, error) in
                        if let results = jsonDoc?[Constants.ParseJSONResponseKeys.Results] as? [[String: AnyObject]] {
                            if let studentInformation = results.first {
                                completionHandler(StudentInformation(studentInformation), nil)
                                return
                            }
                            completionHandler(nil, nil)
                            return
                        }
                        let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
                        completionHandler(nil, NSError(domain: "studentInformation", code: 1, userInfo: userInfo))
                    })
                }
            }
        }
    }
    
    
    func postStudentLocation(info: StudentInformation, completionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        let paramHeaders = [
            Constants.ParseParameterKeys.APIKey       : Constants.ParseParametersValues.APIKey,
            Constants.ParseParameterKeys.ApplicationID: Constants.ParseParametersValues.ApplicationID,
            ] as [String: AnyObject]
        
        let jsonBody = "{\"uniqueKey\": \"\(info.uniqueKey)\", \"firstName\": \"\(info.firstName)\", \"lastName\": \"\(info.lastName)\",\"mapString\": \"\(info.mapString)\", \"mediaURL\": \"\(info.mediaURL)\",\"latitude\": \(info.latitude), \"longitude\": \(info.longitude)}"
        
        _ = taskForPOSTMethod(Constants.Udacity.StudentLocation, parameters: [:], requestHeaderParameters: paramHeaders, jsonBody: jsonBody, apiType: .parse) { (data, error) in
            if let error = error {
                print(error)
                completionHandler(false, error)
            } else {
                
                struct Response: Codable {
                    let createdAt: String?
                    let objectId: String?
                }
                
                var response: Response!
                do {
                    if let data = data {
                        let jsonDecoder = JSONDecoder()
                        response = try jsonDecoder.decode(Response.self, from: data)
                        if let response = response, response.createdAt != nil {
                            completionHandler(true, nil)
                        }
                    }
                } catch {
                    let msg = "Could not parse the data as JSON: \(error.localizedDescription)"
                    print(msg)
                    let userInfo = [NSLocalizedDescriptionKey : msg]
                    completionHandler(false, NSError(domain: "postStudentLocation", code: 1, userInfo: userInfo))
                }
                
            }
        }
    }
    
    
    func updateStudentLocation(info: StudentInformation, completionHandler: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        let paramHeaders = [
            Constants.ParseParameterKeys.APIKey       : Constants.ParseParametersValues.APIKey,
            Constants.ParseParameterKeys.ApplicationID: Constants.ParseParametersValues.ApplicationID,
            ] as [String: AnyObject]
        
        let jsonBody = "{\"uniqueKey\": \"\(info.uniqueKey)\", \"firstName\": \"\(info.firstName)\", \"lastName\": \"\(info.lastName)\",\"mapString\": \"\(info.mapString)\", \"mediaURL\": \"\(info.mediaURL)\",\"latitude\": \(info.latitude), \"longitude\": \(info.longitude)}"
        
        let url = Constants.Udacity.StudentLocation + "/" + (info.locationID ?? "")
        
        _ = taskForPUTMethod(url, parameters: [:], requestHeaderParameters: paramHeaders, jsonBody: jsonBody, apiType: .parse, completionHandlerForPUT: { (data, error) in
            if let error = error {
                print(error)
                completionHandler(false, error)
            } else {
                
                struct Response: Codable {
                    let updatedAt: String?
                }
                
                var response: Response!
                do {
                    if let data = data {
                        let jsonDecoder = JSONDecoder()
                        response = try jsonDecoder.decode(Response.self, from: data)
                        if let response = response, response.updatedAt != nil {
                            completionHandler(true, nil)
                        }
                    }
                } catch {
                    let msg = "Could not parse the data as JSON: \(error.localizedDescription)"
                    print(msg)
                    let userInfo = [NSLocalizedDescriptionKey : msg]
                    completionHandler(false, NSError(domain: "updateStudentLocation", code: 1, userInfo: userInfo))
                }
                
            }
        })
    }
    
    // MARK: - Helpers
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    func parseStudentInfo(data: Data?) -> (StudentInfo?, NSError?) {
        var response: (studentInfo: StudentInfo?, error: NSError?) = (nil, nil)
        do {
            if let data = data {
                let jsonDecoder = JSONDecoder()
                response.studentInfo = try jsonDecoder.decode(StudentInfo.self, from: data)
            }
        } catch {
            print("Could not parse the data as JSON: \(error.localizedDescription)")
            let userInfo = [NSLocalizedDescriptionKey : error]
            response.error = NSError(domain: "parseStudentInfo", code: 1, userInfo: userInfo)
        }
        return response
    }
    
    func parseUserSession(data: Data?) -> (UserSession?, NSError?) {
        var studensLocation: (userSession: UserSession?, error: NSError?) = (nil, nil)
        do {
            if let data = data {
                let jsonDecoder = JSONDecoder()
                studensLocation.userSession = try jsonDecoder.decode(UserSession.self, from: data)
            }
        } catch {
            print("Could not parse the data as JSON: \(error.localizedDescription)")
            let userInfo = [NSLocalizedDescriptionKey : error]
            studensLocation.error = NSError(domain: "parseUserSession", code: 1, userInfo: userInfo)
        }
        return studensLocation
    }
    
    func parseSession(data: Data?) -> (Session?, Error?) {
        var sessionData: (session: Session?, error: Error?) = (nil, nil)
        do {
            
            struct SessionData: Codable {
                let session: Session
            }
            
            if let data = data {
                let jsonDecoder = JSONDecoder()
                sessionData.session = try jsonDecoder.decode(SessionData.self, from: data).session
            }
        } catch {
            print(error)
            sessionData.error = error
        }
        return sessionData
    }
}

