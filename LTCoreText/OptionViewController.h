//
//  OptionViewController.h
//  LTCoreText
//
//  Created by 伊藤 祐輔 on 12/01/09.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *lColLabel;
- (IBAction)lColStepChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *lColVText;
@property (weak, nonatomic) IBOutlet UISwitch *lColVLayout;
- (IBAction)lColVTextChagned:(id)sender;
- (IBAction)lColVLayoutChanged:(id)sender;


@property (weak, nonatomic) IBOutlet UILabel *pColLabel;
- (IBAction)pColStepChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *pColVText;
@property (weak, nonatomic) IBOutlet UISwitch *pColVLayout;
- (IBAction)pColVTextChanged:(id)sender;
- (IBAction)pColVLayoutChanged:(id)sender;

@end
