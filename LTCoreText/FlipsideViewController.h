//
//  FlipsideViewController.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/12/16.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
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