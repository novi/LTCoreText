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

@interface MainViewController()
{
    LTTextView* _mainView;
    NSMutableAttributedString* _attrString;
    LTTextLayouter* _landscapeLayouter;
    LTTextLayouter* _portraitLayouter;
}
@end

@implementation MainViewController

@synthesize flipsidePopoverController = _flipsidePopoverController;

- (id)init
{
    self = [super initWithNibName:@"MainViewController" bundle:nil];
    if (self) {
        _mainView = [[LTTextView alloc] initWithFrame:CGRectZero];
        _mainView.textViewDelegate = self;
        _mainView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        NSData* htmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"]];
        _attrString = [[NSMutableAttributedString alloc] init];
        
        
        for (int i = 0; i < 10; i++) {
            if (i != 0) {
                [_attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n\n\n\n"]];
            }
            [_attrString appendAttributedString:[[NSAttributedString alloc] initWithHTML:htmlData
                                                                                 options:nil
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
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    _mainView = nil;
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
    NSLog(@"run dict: %@", dict);
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor colorWithHue:0.05*(rand()%20) saturation:0.05*(rand()%20) brightness:0.5 alpha:1.0];
    return view;
}
@end
