//
//  DownloadViewController.m
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/08/09.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
//

#import "DownloadViewController.h"

@implementation DownloadViewController
@synthesize urlTextView;
@synthesize delegate;

- (id)init
{
	return [self initWithNibName:@"DownloadViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.urlTextView.delegate = self;
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
	[self setUrlTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
	self.delegate = nil;
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
	self.urlTextView.text = @"";
	
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
	
}

- (IBAction)startDownload:(id)sender
{
	[self.urlTextView resignFirstResponder];
	
	NSURL* url = [NSURL URLWithString:[self.urlTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	[self.delegate downloadViewController:self didSelectDownloadWithURL:url];
}
@end
