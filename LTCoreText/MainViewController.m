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
#import "OptionViewController.h"

@interface MainViewController()
{
    LTTextView* _landscapeView;
    LTTextView* _portraitView;
}

- (void)_updateSlider;
- (void)intertHTMLFileWithPath:(NSString*)path atIndex:(NSUInteger)index;

@end

@implementation MainViewController
@synthesize scrollIndexField = _scrollIndexField;
@synthesize bottomToolbar = _bottomToolbar;
@synthesize pageSlider = _pageSlider;
@synthesize layouterNumField = _pageNumField;
@synthesize filesBarButton = _filesBarButton;
@synthesize slider = _slider;
@synthesize toolbar = _toolbar;
@synthesize layoutBarButton = _layoutBarButton;

@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize downloadPopoverController;
@synthesize optionPopoverController;

- (id)init
{
    self = [super initWithNibName:@"MainViewController" bundle:nil];
    if (self) {
        _landscapeView = [[LTTextView alloc] initWithFrame:CGRectZero];
        _landscapeView.textViewDelegate = self;
        //_landscapeView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        _portraitView = [[LTTextView alloc] initWithFrame:CGRectZero];
        _portraitView.textViewDelegate = self;
        //_portraitView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        UITapGestureRecognizer* gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleToolbar:)];
        [_landscapeView addGestureRecognizer:gr];
        
        UITapGestureRecognizer* gr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleToolbar:)];
        [_portraitView addGestureRecognizer:gr2];
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
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        _landscapeView.hidden = NO;
        _portraitView.hidden = YES;
    } else {
        _landscapeView.hidden = YES;
        _portraitView.hidden = NO;
    }
    
    _landscapeView.frame = CGRectMake(0, 0, 1024, 768-20);
    _portraitView.frame = CGRectMake(0, 0, 768, 1024-20);
    
    [self.view addSubview:_landscapeView];
    [self.view addSubview:_portraitView];
    
    [self.view bringSubviewToFront:self.bottomToolbar];
    [self.view bringSubviewToFront:self.toolbar];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    _landscapeView = nil;
    _portraitView = nil;
    [self setToolbar:nil];
    [self setLayoutBarButton:nil];
    [self setSlider:nil];
    [self setLayouterNumField:nil];
    [self setFilesBarButton:nil];
    [self setPageSlider:nil];
    [self setScrollIndexField:nil];
    [self setBottomToolbar:nil];
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
        _portraitView.hidden = YES;
        _landscapeView.hidden = NO;
        [_landscapeView redrawPageIfNeeded];
    } else {
        _landscapeView.hidden = YES;
        _portraitView.hidden = NO;
        [_portraitView redrawPageIfNeeded];
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self _updateSlider];
}


#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self.flipsidePopoverController dismissPopoverAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{
    if (!self.flipsidePopoverController) {
        FlipsideViewController *controller = [[FlipsideViewController alloc] initWithStyle:UITableViewStylePlain];
        controller.delegate = self;
        
        self.flipsidePopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
    }
    if ([self.flipsidePopoverController isPopoverVisible]) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
    } else {
        [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    }
}

-(void)flipsideViewController:(FlipsideViewController *)controller didSelectFileWithPath:(NSString *)path
{
    [self intertHTMLFileWithPath:path atIndex:self.slider.value];
    [self.flipsidePopoverController dismissPopoverAnimated:YES];
}



#pragma mark - Toolbar


- (IBAction)toggleLayout:(id)sender
{
    if (_landscapeView.layoutMode == LTTextViewLayoutModeNormal) {
        _landscapeView.layoutMode = LTTextViewLayoutModeReverse;
        _portraitView.layoutMode = LTTextViewLayoutModeReverse;
        self.layoutBarButton.title = @"Reverse";
    } else if (_landscapeView.layoutMode == LTTextViewLayoutModeReverse) {
        _landscapeView.layoutMode = LTTextViewLayoutModeVertical;
        _portraitView.layoutMode = LTTextViewLayoutModeVertical;
        self.layoutBarButton.title = @"Vertical";
    } else if (_landscapeView.layoutMode == LTTextViewLayoutModeVertical) {
        _landscapeView.layoutMode = LTTextViewLayoutModeNormal;
        _portraitView.layoutMode = LTTextViewLayoutModeNormal;
        self.layoutBarButton.title = @"Layout";
    }
}

- (void)toggleToolbar:(id)sender
{
    self.bottomToolbar.hidden = (self.toolbar.hidden = self.toolbar.hidden ? NO : YES);
}

- (void)_updateSlider
{
    if (_landscapeView.layouters.count == 0) {
        self.slider.maximumValue = 1;
    } else {
        self.slider.maximumValue = _landscapeView.layouters.count;
    }
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        self.pageSlider.value = _landscapeView.scrollIndex;
        self.pageSlider.maximumValue = _landscapeView.allPageCount-1;
    } else {
        self.pageSlider.value = _portraitView.scrollIndex;
        self.pageSlider.maximumValue = _portraitView.allPageCount-1;
    }
    
    self.scrollIndexField.text = [NSString stringWithFormat:@"%d", (int)self.pageSlider.value];
}

- (IBAction)sliderChanged:(id)sender
{
    self.layouterNumField.text = [NSString stringWithFormat:@"%d", (int)self.slider.value];
}

- (IBAction)removePage:(id)sender
{
    NSUInteger index = self.slider.value;
    [_portraitView removeLayouterAtIndex:index];
    [_landscapeView removeLayouterAtIndex:index];
    
    [self _updateSlider];
}

#pragma mark - Download

- (IBAction)showDownload:(id)sender
{
    if (!self.downloadPopoverController) {
        DownloadViewController *controller = [[DownloadViewController alloc] init];
        controller.delegate = self;
        
        self.downloadPopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
    }
    if ([self.downloadPopoverController isPopoverVisible]) {
        [self.downloadPopoverController dismissPopoverAnimated:YES];
    } else {
        [self.downloadPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    }
}

-(void)downloadViewController:(id)vc didSelectDownloadWithURL:(NSURL *)url
{
    NSURLRequest* req = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse * res, NSData * data, NSError * error) {
                               if (data.length) {
                                   NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                   NSString* documentsDirectory = [paths objectAtIndex:0];
                                   NSString* filename = [url lastPathComponent];
                                   if ( ! filename.length) {
                                       filename = [url host];
                                   }   
                                   filename = [filename stringByAppendingPathExtension:@"html"];
                                   [data writeToFile:[documentsDirectory stringByAppendingPathComponent:filename] atomically:NO];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                      [self intertHTMLFileWithPath:[documentsDirectory stringByAppendingPathComponent:filename]
                                                           atIndex:self.slider.value];
                                       [self.downloadPopoverController dismissPopoverAnimated:YES];
                                   });
                               } else {
                                   [[[UIAlertView alloc] initWithTitle:@"download error"
                                                              message:error.localizedDescription
                                                             delegate:nil
                                                     cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                               }
                           }];
}

#pragma mark - Option


- (IBAction)showOption:(id)sender
{
    if (!self.optionPopoverController) {
        OptionViewController *controller = [[OptionViewController alloc] init];
        
        
        self.optionPopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
    }
    if ([self.optionPopoverController isPopoverVisible]) {
        [self.optionPopoverController dismissPopoverAnimated:YES];
    } else {
        [self.optionPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    }
}


#pragma mark - TextView

- (void)intertHTMLFileWithPath:(NSString*)path atIndex:(NSUInteger)index
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* htmlData = [NSData dataWithContentsOfFile:path];
        
        
        NSMutableDictionary* options = [NSMutableDictionary dictionaryWithCapacity:1];
        [options setObject:[NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]] forKey:NSBaseURLDocumentOption];
        
        NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] init];
        
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithHTML:htmlData
                                                                            options:options
                                                                 documentAttributes:nil]];
        
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        //_attrString = [[NSAttributedString alloc] initWithString:_attrString.string];
        [attrString addAttribute:(id)kCTVerticalFormsAttributeName value:[NSNumber numberWithBool:[defaults boolForKey:@"lColVText"]] range:NSMakeRange(0, attrString.length)];
        //[_attrString addAttribute:(id)kCTLineBreakByWordWrapping value:[NSNumber numberWithBool:YES] range:NSMakeRange(0, _attrString.length)];
        
        LTTextLayouter* landscapeLayouter = [[LTTextLayouter alloc] initWithAttributedString:attrString
                                                                                   frameSize:CGSizeMake(1024, 768-20)
                                                                                     options:nil];
        landscapeLayouter.columnCount = [defaults integerForKey:@"lCol"];
        landscapeLayouter.verticalText = [defaults boolForKey:@"lColVLayout"];
        landscapeLayouter.contentInset = UIEdgeInsetsMake(100, 80, 50, 90);
        landscapeLayouter.columnSpace = 40;
        landscapeLayouter.justifyThreshold = 0.8;
        //_landscapeLayouter.contentInset = UIEdgeInsetsMake(40, 30, 20, 10);
        [landscapeLayouter layoutIfNeeded];
        
        
        [attrString removeAttribute:(id)kCTVerticalFormsAttributeName range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:(id)kCTVerticalFormsAttributeName value:[NSNumber numberWithBool:[defaults boolForKey:@"pColVText"]] range:NSMakeRange(0, attrString.length)];
        LTTextLayouter*  portraitLayouter = [[LTTextLayouter alloc] initWithAttributedString:attrString
                                                                                   frameSize:CGSizeMake(768, 1024-20)
                                                                                     options:nil];
        
        portraitLayouter.columnCount = [defaults integerForKey:@"pCol"];
        portraitLayouter.verticalText = [defaults boolForKey:@"pColVLayout"];
        portraitLayouter.contentInset = UIEdgeInsetsMake(120, 100, 50, 40);
        portraitLayouter.justifyThreshold = 0.8;
        portraitLayouter.columnSpace = 40;
        [portraitLayouter layoutIfNeeded]; 
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_portraitView insertLayouter:portraitLayouter atIndex:index];
            [_landscapeView insertLayouter:landscapeLayouter atIndex:index];
            
            [self _updateSlider];
            self.filesBarButton.title = @"Files";
        });
        
    
    });
    
    //NSLog(@"%@", [_portraitLayouter valueForKey:@"attachments"]);
    
    self.filesBarButton.title = @"Loading...";
}

#pragma mark - Text View Delegate

-(UIView *)textview:(LTTextView *)textView viewForRunDictionary:(NSDictionary *)dict
{
    DTTextAttachment* attachment = [dict objectForKey:@"DTTextAttachment"];
    //NSLog(@"run dict: %@", dict);
    
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

-(void)textviewDidChangeScrollIndex:(LTTextView *)textView
{
    [self _updateSlider];
}

- (IBAction)pageSliderChanged:(id)sender 
{
    self.scrollIndexField.text = [NSString stringWithFormat:@"%d", (int)self.pageSlider.value];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [_landscapeView scrollToPageIndex:self.pageSlider.value animated:NO];
    } else {
        [_portraitView scrollToPageIndex:self.pageSlider.value animated:NO];
    }
}
- (IBAction)scrollIndexChanged:(id)sender
{
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [_landscapeView scrollToPageIndex:[self.scrollIndexField.text integerValue] animated:YES];
    } else {
        [_portraitView scrollToPageIndex:[self.scrollIndexField.text integerValue] animated:YES];
    }
}
@end
