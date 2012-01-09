//
//  DownloadViewController.h
//  LTCoreText
//
//  Created by ito on H.23/08/09.
//  Copyright 平成23年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DownloadViewControllerDelegate <NSObject>

- (void)downloadViewController:(id)vc didSelectDownloadWithURL:(NSURL*)url;

@end

@interface DownloadViewController : UIViewController<UITextViewDelegate>
{
	UITextView *urlTextView;
}

- (IBAction)startDownload:(id)sender;
@property (retain, nonatomic) IBOutlet UITextView *urlTextView;

@property (nonatomic, assign) id<DownloadViewControllerDelegate> delegate;
@end
