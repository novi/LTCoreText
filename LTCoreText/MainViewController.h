//
//  MainViewController.h
//  LTCoreText
//
//  Created by 伊藤 祐輔 on 11/12/16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "LTTextView.h"
#import "DownloadViewController.h"


@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, LTTextViewDelegate, DownloadViewControllerDelegate>

@property (strong, nonatomic) UIPopoverController* flipsidePopoverController;
@property (strong, nonatomic) UIPopoverController* downloadPopoverController;
@property (strong, nonatomic) UIPopoverController* optionPopoverController;

- (IBAction)showInfo:(id)sender;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *layoutBarButton;
- (IBAction)toggleLayout:(id)sender;
- (IBAction)showDownload:(id)sender;
@property (weak, nonatomic) IBOutlet UISlider *slider;
- (IBAction)sliderChanged:(id)sender;
- (IBAction)removePage:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *layouterNumField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filesBarButton;
- (IBAction)showOption:(id)sender;

@property (weak, nonatomic) IBOutlet UISlider *pageSlider;
- (IBAction)pageSliderChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *scrollIndexField;

@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;
- (IBAction)scrollIndexChanged:(id)sender;

@end
