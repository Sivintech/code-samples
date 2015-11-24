//
//  XMPTUserAutenticator.m
//  XMPPTest
//
//  Created by Arthur Gevorkyan on 02.11.15.
//  Copyright © 2015 Arthur Gevorkyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPTUserAuthenticator.h"



static XMPTUserAuthenticator *__sharedInstance = nil;

@implementation XMPTUserAuthenticator

- (nullable NSString *)password
{
    NSDictionary *credentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:self.loginProtectionSpace];
    NSURLCredential *credential = [credentials.objectEnumerator nextObject];
    return credential.password;
}


+ (instancetype)alloc
{
    @synchronized(self)
    {
        XMPTUserAuthenticator *instance = __sharedInstance ? __sharedInstance : [super alloc];
        return instance;
    }
}

- (nonnull instancetype)init
{
    if (__sharedInstance == nil)
    {
        if (self = [super init])
        {
            _loginProtectionSpace = [[NSURLProtectionSpace alloc] initWithHost:@"localhost" port:5222 protocol:nil realm:nil authenticationMethod:nil];
            __sharedInstance = self;
        }
    }
    
    return self;
}

+ (instancetype)sharedInstance
{
    return [[self alloc] init];
}

- (void)generateUserCredentialWith:(NSString *)login password:(NSString *)password
{
    NSURLCredential *credential = [NSURLCredential credentialWithUser:login password:password persistence:NSURLCredentialPersistencePermanent];
    
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:self.loginProtectionSpace];
}


- (void)initiateAuthenticationDataRequestAtViewController:(nonnull UIViewController *)viewController submissionHandler:(nullable void(^)(XMPTChatParticipantIdentity *_Nullable identity))handler
{
    __block XMPTChatParticipantIdentity *identity = nil;
    __block UITextField *loginTextField = nil;
    __block UITextField *passwordTextField = nil;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Login" message:@"Please enter your credentials" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Click" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self generateUserCredentialWith:loginTextField.text password:passwordTextField.text];
        
        identity = [[XMPTChatParticipantIdentity alloc] initWithJabberIDString:loginTextField.text displayName:nil];
        if (handler)
        {
            handler(identity);
        }
    }]];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"JID:";
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.secureTextEntry = NO;
        
#warning non-prod stub!
#if DEBUG
        textField.text = @"arthur@sivintech";
#endif
        
        loginTextField = textField;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Password:";
        textField.secureTextEntry = YES;

#warning non-prod stub!
#if DEBUG
        textField.text = @"abcdefgh";
#endif
        passwordTextField = textField;
    }];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

@end
