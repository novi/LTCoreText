//
//  FlipsideViewController.h
//  LTCoreText
//
//  Created by 伊藤 祐輔 on 11/12/16.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewController:(FlipsideViewController*)controller didSelectFileWithPath:(NSString*)path;
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UITableViewController
{
	NSArray* _files;
}

@property ( nonatomic, assign) IBOutlet id <FlipsideViewControllerDelegate> delegate;

- (void)_refreshList;
- (IBAction)done:(id)sender;

@end