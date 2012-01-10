//
//  OptionViewController.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2012/01/09.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
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
- (IBAction)lJustifyChanged:(id)sender;
- (IBAction)pJustifyChanged:(id)sender;

@end
