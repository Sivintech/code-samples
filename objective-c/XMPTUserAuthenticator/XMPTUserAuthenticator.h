//
//  XMPTUserAutenticator.h
//  Copyright © 2015 Arthur Gevorkyan. All rights reserved.
//

/*
    The class is designed for requesting and managing user credentials 
 (i.e. showing the login UI flow, collecting input, generating and storing user credentials).
 Act as part of an XMPP-compiant application build on top of the Robie Hanson's
 XMPP framework.
 
 */

#import <Foundation/Foundation.h>
#import "XMPTChatParticipantIdentity.h"

@interface XMPTUserAuthenticator : NSObject

@property (nonatomic, strong, nullable, readonly) XMPTChatParticipantIdentity *currentUserIdentity;

// Used for storing user credentials in a secure way. Defaults to localhost:5222.
@property (nonatomic, strong, nonnull) NSURLProtectionSpace *loginProtectionSpace;

// Available only after the authentication procedue ended
// (use it after initiateAuthenticationDataRequestAtViewController: submissionHandler:).

@property (nonatomic, copy, nullable, readonly) NSString *password;


+ (nonnull instancetype)sharedInstance;

- (void)initiateAuthenticationDataRequestAtViewController:(nonnull UIViewController *)viewController submissionHandler:(nullable void(^)(XMPTChatParticipantIdentity *_Nullable identity))handler;


@end
