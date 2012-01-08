//
//  MainViewController.m
//  LTCoreText
//
//  Created by 伊藤 祐輔 on 11/12/16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "LTTextView.h"
#import "NSAttributedString+HTML.h"
#import "LTTextImageView.h"
#import "DTTextAttachment.h"

@interface MainViewController()
{
    LTTextView* _mainView;
    NSMutableAttributedString* _attrString;
    LTTextLayouter* _landscapeLayouter;
    LTTextLayouter* _portraitLayouter;
}
@end

@implementation MainViewController
@synthesize toolbar = _toolbar;
@synthesize layoutBarButton = _layoutBarButton;

@synthesize flipsidePopoverController = _flipsidePopoverController;

- (id)init
{
    self = [super initWithNibName:@"MainViewController" bundle:nil];
    if (self) {
        _mainView = [[LTTextView alloc] initWithFrame:CGRectZero];
        _mainView.textViewDelegate = self;
        _mainView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        //_mainView.layoutMode = LTTextViewLayoutModeVertical;
        
        NSData* htmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"]];
        _attrString = [[NSMutableAttributedString alloc] init];
        
        NSMutableDictionary* options = [NSMutableDictionary dictionaryWithCapacity:1];
        [options setObject:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]] forKey:NSBaseURLDocumentOption];
        
        for (int i = 0; i < 20; i++) {
            if (i != 0) {
                [_attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n\n\n\n"]];
            }
            [_attrString appendAttributedString:[[NSAttributedString alloc] initWithHTML:htmlData
                                                                                 options:options
                                                                      documentAttributes:nil]];
        }
        
        _landscapeLayouter = [[LTTextLayouter alloc] initWithAttributedString:_attrString
                                                                          frameSize:CGSizeMake(1024, 768-20)
                                                                            options:nil];
        _landscapeLayouter.columnCount = 3;
        [_landscapeLayouter layoutIfNeeded];
        
        _portraitLayouter = [[LTTextLayouter alloc] initWithAttributedString:_attrString
                                                                   frameSize:CGSizeMake(768, 1024-20)
                                                                     options:nil];
        
        _portraitLayouter.columnCount = 2;
        [_portraitLayouter layoutIfNeeded];
        
        NSLog(@"%@", [_portraitLayouter valueForKey:@"attachments"]);
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    _mainView.frame = self.view.bounds;
    [self.view addSubview:_mainView];
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [_mainView insertLayouter:_landscapeLayouter atIndex:0];
    } else {
        if (_portraitLayouter) {
            [_mainView insertLayouter:_portraitLayouter atIndex:0];
        }
    }
    
    [self.view bringSubviewToFront:self.toolbar];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    _mainView = nil;
    [self setToolbar:nil];
    [self setLayoutBarButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        [_mainView removeLayouterAtIndex:0];
        [_mainView insertLayouter:_landscapeLayouter atIndex:0];
    } else {
        [_mainView removeLayouterAtIndex:0];
        [_mainView insertLayouter:_portraitLayouter atIndex:0];
    }
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self.flipsidePopoverController dismissPopoverAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{
    if (!self.flipsidePopoverController) {
        FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil];
        controller.delegate = self;
        
        self.flipsidePopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
    }
    if ([self.flipsidePopoverController isPopoverVisible]) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    } else {
        [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

-(UIView *)textview:(LTTextView *)textView viewForRunDictionary:(NSDictionary *)dict
{
    DTTextAttachment* attachment = [dict objectForKey:@"DTTextAttachment"];
    NSLog(@"run dict: %@", dict);
    
    /*UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor colorWithHue:0.05*(rand()%20) saturation:0.05*(rand()%20) brightness:0.5 alpha:1.0];
    return view;
     */
    LTTextImageView* imageView = [[LTTextImageView alloc] init];
    imageView.imageURL = attachment.contentURL;
    imageView.displaySize = attachment.displaySize;
    [imageView startDownload];
    
    return imageView;
}
- (IBAction)toggleLayout:(id)sender
{
    if (_mainView.layoutMode == LTTextViewLayoutModeNormal) {
        _mainView.layoutMode = LTTextViewLayoutModeReverse;
        self.layoutBarButton.title = @"Reverse";
    } else if (_mainView.layoutMode == LTTextViewLayoutModeReverse) {
        _mainView.layoutMode = LTTextViewLayoutModeVertical;
        self.layoutBarButton.title = @"Vertical";
    } else if (_mainView.layoutMode == LTTextViewLayoutModeVertical) {
        _mainView.layoutMode = LTTextViewLayoutModeNormal;
        self.layoutBarButton.title = @"Layout";
    }
}
@end
