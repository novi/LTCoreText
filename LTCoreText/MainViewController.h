//
//  MainViewController.h
//  LTCoreText
//
//  Created by 伊藤 祐輔 on 11/12/16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "LTTextView.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, LTTextViewDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

- (IBAction)showInfo:(id)sender;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *layoutBarButton;
- (IBAction)toggleLayout:(id)sender;

@end
