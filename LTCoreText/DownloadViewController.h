//
//  DownloadViewController.h
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/08/09.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
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
