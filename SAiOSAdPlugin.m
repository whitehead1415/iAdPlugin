//
//  SAiOSAdPlugin.m
//  Ad Plugin for PhoneGap
//
//  Created by shazron on 10-07-12.
//  Copyright 2010 Shazron Abdullah. All rights reserved.
//  Cordova v1.5.0 Support added 2012 @RandyMcMillan
//

#import "SAiOSAdPlugin.h"

//#ifdef CORDOVA_FRAMEWORK
#import <Cordova/CDVDebug.h>
//#else
//#import "CDVDebug.h"
//#endif

@interface SAiOSAdPlugin(PrivateMethods)

- (void) __prepare:(BOOL)atBottom;
- (void) __showAd:(BOOL)show;

@end


@implementation SAiOSAdPlugin

@synthesize adView;
@synthesize bannerIsVisible, bannerIsInitialized, bannerIsAtBottom, isLandscape;

#pragma mark -
#pragma mark Public Methods

- (void) resizeViews
{
    Class adBannerViewClass = NSClassFromString(@"ADBannerView");
	if (adBannerViewClass && self.adView)
	{
        CGRect webViewFrame = [super webView].frame;
        CGRect superViewFrame = [[super webView] superview].frame;
        CGRect adViewFrame = self.adView.frame;
        
        BOOL adIsShowing = [[[super webView] superview].subviews containsObject:self.adView];
        if (adIsShowing) 
        {
            if (self.bannerIsAtBottom) {
                webViewFrame.origin.y = 0;
                CGRect adViewFrame = self.adView.frame;
                CGRect superViewFrame = [[super webView] superview].frame;
                adViewFrame.origin.y = (self.isLandscape ? superViewFrame.size.width : superViewFrame.size.height) - adViewFrame.size.height;
                self.adView.frame = adViewFrame;
            } else {
                webViewFrame.origin.y = adViewFrame.size.height;
            }
            
            webViewFrame.size.height = self.isLandscape? (superViewFrame.size.width - adViewFrame.size.height) : (superViewFrame.size.height - adViewFrame.size.height);
        } 
        else 
        {
            webViewFrame.size = self.isLandscape? CGSizeMake(superViewFrame.size.height, superViewFrame.size.width) : superViewFrame.size;
            webViewFrame.origin = CGPointZero;
        }
        
        [UIView beginAnimations:@"blah" context:NULL];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        
        [super webView].frame = webViewFrame;
        
        [UIView commitAnimations];
    }
}

- (void) orientationChanged:(CDVInvokedUrlCommand*)command;
{
    NSInteger orientation = [[command.arguments objectAtIndex:0] integerValue];

    switch (orientation) {
        // landscape
        case 90:
        case -90:
            self.isLandscape = YES;
            break;
        // portrait
        case 0:
        case 180:
            self.isLandscape = NO;
            break;
        default:
            break;
    }
    
    Class adBannerViewClass = NSClassFromString(@"ADBannerView");
    if (adBannerViewClass && self.adView)
    {
        self.adView.currentContentSizeIdentifier = self.isLandscape ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifierPortrait;
        [self resizeViews];
    }
}

- (void) prepare:(CDVInvokedUrlCommand*)command;
{
	NSUInteger argc = [command.arguments count];
	if (argc > 1) {
		return;
	}
    
	NSString* atBottomValue = [command.arguments objectAtIndex:0];
	[self __prepare:[atBottomValue boolValue]];
}

- (void) showAd:(CDVInvokedUrlCommand*)command;
{
	NSUInteger argc = [command.arguments count];
	if (argc > 1) {
		return;
	}
	
	NSString* showValue = [command.arguments objectAtIndex:0];
	[self __showAd:[showValue boolValue]];
}

#pragma mark -
#pragma mark Private Methods

- (void) __prepare:(BOOL)atBottom
{
	NSLog(@"SAiOSAdPlugin Prepare Ad At Bottom: %d", atBottom);
	
	Class adBannerViewClass = NSClassFromString(@"ADBannerView");
	if (adBannerViewClass && !self.adView)
	{
		self.adView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        // we are still using these constants even though they are deprecated - if it is changed, iOS 4 devices < 4.3 will crash.
        // will need to do a run-time iOS version check	
		self.adView.requiredContentSizeIdentifiers = [NSSet setWithObjects: ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];		

		self.adView.delegate = self;
        
        NSString* contentSizeId = (self.isLandscape ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifierPortrait);

        self.adView.currentContentSizeIdentifier = contentSizeId;
		
		if (atBottom) {
			self.bannerIsAtBottom = YES;
		}
        
		self.bannerIsVisible = NO;
		self.bannerIsInitialized = YES;
	}
}

- (void) __showAd:(BOOL)show
{
	NSLog(@"SAiOSAdPlugin Show Ad: %d", show);
	
	if (!self.bannerIsInitialized){
		[self __prepare:NO];
	}
	
	if (!(NSClassFromString(@"ADBannerView") && self.adView)) { // ad classes not available
		return;
	}
	
	if (show == self.bannerIsVisible) { // same state, nothing to do
		return;
	}
	
	if (show)
	{
		[UIView beginAnimations:@"blah" context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];

		[[[super webView] superview] addSubview:self.adView];
		[[[super webView] superview] bringSubviewToFront:self.adView];
        [self resizeViews];
		
		[UIView commitAnimations];

		self.bannerIsVisible = YES;
	}
	else 
	{
		[UIView beginAnimations:@"blah" context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		
		[self.adView removeFromSuperview];
        [self resizeViews];
		
		[UIView commitAnimations];
		
		self.bannerIsVisible = NO;
	}
	
}

#pragma mark -
#pragma ADBannerViewDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	Class adBannerViewClass = NSClassFromString(@"ADBannerView");
    if (adBannerViewClass)
    {

		[super writeJavascript:@"Cordova.fireEvent('iAdBannerViewDidLoadAdEvent');"];

    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError*)error
{
	Class adBannerViewClass = NSClassFromString(@"ADBannerView");
    if (adBannerViewClass)
    {
		NSString* jsString = 
		@"(function(){"
		"var e = document.createEvent('Events');"
		"e.initEvent('iAdBannerViewDidFailToReceiveAdWithErrorEvent');"
		"e.error = '%@';"
		"document.dispatchEvent(e);"
		"})();";
		
		[super writeJavascript:[NSString stringWithFormat:jsString, [error description]]];
    }
}

@end
