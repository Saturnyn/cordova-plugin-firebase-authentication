#import "FirebaseAuthenticationPlugin.h"
@import CommonCrypto;

@implementation FirebaseAuthenticationPlugin

- (void)pluginInitialize {
    NSLog(@"Starting Firebase Authentication plugin");

    if(![FIRApp defaultApp]) {
        [FIRApp configure];
    }
}

- (void)setAuthStateChanged:(CDVInvokedUrlCommand*)command {
    BOOL disable = [[command.arguments objectAtIndex:0] boolValue];
    if (self.authChangedHandler) {
        [[FIRAuth auth] removeAuthStateDidChangeListener:self.authChangedHandler];
        self.authChangedHandler = nil;
    }
    if (!disable) {
        self.authChangedHandler = [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth* auth, FIRUser* user) {
           CDVPluginResult *pluginResult = [self getProfileResult:user];
           [pluginResult setKeepCallbackAsBool:YES];
           [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
       }];
    }
}

- (void)getCurrentUser:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [self getProfileResult:[FIRAuth auth].currentUser];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getIdToken:(CDVInvokedUrlCommand *)command {
    BOOL forceRefresh = [[command.arguments objectAtIndex:0] boolValue];
    FIRUser *user = [FIRAuth auth].currentUser;

    if (user) {
        [user getIDTokenForcingRefresh:forceRefresh completion:^(NSString *token, NSError *error) {
            CDVPluginResult *pluginResult;
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
            }

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"User must be signed in"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)createUserWithEmailAndPassword:(CDVInvokedUrlCommand *)command {
    NSString* email = [command.arguments objectAtIndex:0];
    NSString* password = [command.arguments objectAtIndex:1];

    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)sendEmailVerification:(CDVInvokedUrlCommand *)command {
    FIRUser *currentUser = [FIRAuth auth].currentUser;

    if (currentUser) {
        [currentUser sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
            [self respondWith:error callbackId:command.callbackId];
        }];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"User must be signed in"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)sendPasswordResetEmail:(CDVInvokedUrlCommand *)command {
    NSString* email = [command.arguments objectAtIndex:0];

    [[FIRAuth auth] sendPasswordResetWithEmail:email completion:^(NSError *_Nullable error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)signInWithEmailAndPassword:(CDVInvokedUrlCommand *)command {
    NSString* email = [command.arguments objectAtIndex:0];
    NSString* password = [command.arguments objectAtIndex:1];

    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)signInAnonymously:(CDVInvokedUrlCommand *)command {
    [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)signInWithGoogle:(CDVInvokedUrlCommand *)command {
    NSString* idToken = [command.arguments objectAtIndex:0];
    NSString* accessToken = [command.arguments objectAtIndex:1];

    FIRAuthCredential *credential = [FIRGoogleAuthProvider credentialWithIDToken:idToken
                                                                     accessToken:accessToken];
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)signInWithFacebook:(CDVInvokedUrlCommand *)command {
    NSString* accessToken = [command.arguments objectAtIndex:0];

    FIRAuthCredential *credential = [FIRFacebookAuthProvider credentialWithAccessToken:accessToken];
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)signInWithTwitter:(CDVInvokedUrlCommand *)command {
    NSString* token = [command.arguments objectAtIndex:0];
    NSString* secret = [command.arguments objectAtIndex:1];

    FIRAuthCredential *credential = [FIRTwitterAuthProvider credentialWithToken:token
                                                                         secret:secret];
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)signInWithVerificationId:(CDVInvokedUrlCommand*)command {
    NSString* verificationId = [command.arguments objectAtIndex:0];
    NSString* smsCode = [command.arguments objectAtIndex:1];

    FIRAuthCredential *credential = [[FIRPhoneAuthProvider provider]
            credentialWithVerificationID:verificationId
                        verificationCode:smsCode];

    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)verifyPhoneNumber:(CDVInvokedUrlCommand*)command {
    NSString* phoneNumber = [command.arguments objectAtIndex:0];

    [[FIRPhoneAuthProvider provider] verifyPhoneNumber:phoneNumber
                                            UIDelegate:nil
                                            completion:^(NSString* verificationId, NSError* error) {
        CDVPluginResult *pluginResult;
        if (error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:verificationId];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)signInWithCustomToken:(CDVInvokedUrlCommand *)command {
    NSString* idToken = [command.arguments objectAtIndex:0];

    [[FIRAuth auth] signInWithCustomToken:idToken
                         completion:^(FIRAuthDataResult *result, NSError *error) {
        [self respondWith:error callbackId:command.callbackId];
    }];
}

- (void)signOut:(CDVInvokedUrlCommand*)command {
    NSError *signOutError;
    CDVPluginResult *pluginResult;

    if ([[FIRAuth auth] signOut:&signOutError]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:signOutError.localizedDescription];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setLanguageCode:(CDVInvokedUrlCommand*)command {
    NSString* languageCode = [command.arguments objectAtIndex:0];
    if (languageCode) {
        [FIRAuth auth].languageCode = languageCode;
    } else {
        [[FIRAuth auth] useAppLanguage];
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) respondWith:(NSError*)error callbackId:(NSString*)callbackId {
    CDVPluginResult *pluginResult;
    if (error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (CDVPluginResult*)getProfileResult:(FIRUser *)user {
    NSDictionary* result = nil;
    if (user) {
        result = @{
            @"uid": user.uid,
            @"providerId": user.providerID,
            @"displayName": user.displayName ? user.displayName : @"",
            @"email": user.email ? user.email : @"",
            @"phoneNumber": user.phoneNumber ? user.phoneNumber : @"",
            @"photoURL": user.photoURL ? user.photoURL.absoluteString : @"",
            @"emailVerified": [NSNumber numberWithBool:user.emailVerified]
        };
    }

    return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
}

//Apple Sign In


- (void)startSignInWithAppleFlow {
  NSString *nonce = [self randomNonce:32];
  self.currentNonce = nonce;
  ASAuthorizationAppleIDProvider *appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
  ASAuthorizationAppleIDRequest *request = [appleIDProvider createRequest];
  request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
  request.nonce = [self stringBySha256HashingString:nonce];

  ASAuthorizationController *authorizationController =
      [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
  authorizationController.delegate = self;
  authorizationController.presentationContextProvider = self;
  [authorizationController performRequests];
}

- (void)authorizationController:(ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization API_AVAILABLE(ios(13.0)) {
  if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
    ASAuthorizationAppleIDCredential *appleIDCredential = authorization.credential;
    NSString *rawNonce = self.currentNonce;
    NSAssert(rawNonce != nil, @"Invalid state: A login callback was received, but no login request was sent.");

    if (appleIDCredential.identityToken == nil) {
      NSLog(@"Unable to fetch identity token.");
      return;
    }

    NSString *idToken = [[NSString alloc] initWithData:appleIDCredential.identityToken
                                              encoding:NSUTF8StringEncoding];
    if (idToken == nil) {
      NSLog(@"Unable to serialize id token from data: %@", appleIDCredential.identityToken);
    }

    // Initialize a Firebase credential.
    FIROAuthCredential *credential = [FIROAuthProvider credentialWithProviderID:@"apple.com"
                                                                        IDToken:idToken
                                                                       rawNonce:rawNonce];

    // Sign in with Firebase.
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRAuthDataResult * _Nullable authResult,
                                           NSError * _Nullable error) {
      if (error != nil) {
        // Error. If error.code == FIRAuthErrorCodeMissingOrInvalidNonce,
        // make sure you're sending the SHA256-hashed nonce as a hex string
        // with your request to Apple.
        return;
      }
      // Sign-in succeeded!
    }];
  }
}

- (void)authorizationController:(ASAuthorizationController *)controller
           didCompleteWithError:(NSError *)error API_AVAILABLE(ios(13.0)) {
  NSLog(@"Sign in with Apple errored: %@", error);
}

- (NSString *)stringBySha256HashingString:(NSString *)input {
  const char *string = [input UTF8String];
  unsigned char result[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(string, (CC_LONG)strlen(string), result);

  NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (NSInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
    [hashed appendFormat:@"%02x", result[i]];
  }
  return hashed;
}

- (NSString *)randomNonce:(NSInteger)length {
  NSAssert(length > 0, @"Expected nonce to have positive length");
  NSString *characterSet = @"0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._";
  NSMutableString *result = [NSMutableString string];
  NSInteger remainingLength = length;

  while (remainingLength > 0) {
    NSMutableArray *randoms = [NSMutableArray arrayWithCapacity:16];
    for (NSInteger i = 0; i < 16; i++) {
      uint8_t random = 0;
      int errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random);
      NSAssert(errorCode == errSecSuccess, @"Unable to generate nonce: OSStatus %i", errorCode);

      [randoms addObject:@(random)];
    }

    for (NSNumber *random in randoms) {
      if (remainingLength == 0) {
        break;
      }

      if (random.unsignedIntValue < characterSet.length) {
        unichar character = [characterSet characterAtIndex:random.unsignedIntValue];
        [result appendFormat:@"%C", character];
        remainingLength--;
      }
    }
  }

  return result;
}


@end
