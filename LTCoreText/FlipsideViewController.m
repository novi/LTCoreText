//
//  FlipsideViewController.m
//  LTCoreText
//
//  Created by Yusuke Ito on 2011/12/16.
//  Copyright 2011-12 Yusuke Ito
//  http://www.opensource.org/licenses/MIT
//

#import "FlipsideViewController.h"

@implementation FlipsideViewController

@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)_refreshList
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	NSMutableArray* htmlFiles = [NSMutableArray array];
	for (NSString* filename in [fm contentsOfDirectoryAtPath:documentsDirectory error:nil]) {
		if ([[[filename pathExtension] lowercaseString] isEqualToString:@"html"]) {
			if (! [filename hasSuffix:@"-orig.html"]) {
				[htmlFiles addObject:filename];
			}
		}
	}
	
	[htmlFiles sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSString* filePath1 = [documentsDirectory stringByAppendingPathComponent:obj1];
		NSString* filePath2 = [documentsDirectory stringByAppendingPathComponent:obj2];
		NSDate* fmod1 = [[fm attributesOfItemAtPath:filePath1 error:nil] fileModificationDate];
		NSDate* fmod2 = [[fm attributesOfItemAtPath:filePath2 error:nil] fileModificationDate];
		if (fmod1.timeIntervalSince1970 > fmod2.timeIntervalSince1970) {
			return NSOrderedAscending;
		} else if (fmod1.timeIntervalSince1970 < fmod2.timeIntervalSince1970) {
			return NSOrderedDescending;
		} else {
			return NSOrderedSame;
		}
	}];
	

	_files = htmlFiles;
	
	[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	
	[self _refreshList];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self _refreshList];
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

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

#pragma mark - Table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_files count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0];
	NSString* path = [documentsDirectory stringByAppendingPathComponent:[_files objectAtIndex:indexPath.row]];
	
	NSDictionary* metadata = [NSDictionary dictionaryWithContentsOfFile:[path.stringByDeletingPathExtension stringByAppendingPathExtension:@"plist"]];
	
	UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
	
	cell.textLabel.text = [metadata objectForKey:@"title"];
	cell.detailTextLabel.text = [_files objectAtIndex:indexPath.row];
	
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0];
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self.delegate flipsideViewController:self didSelectFileWithPath:[documentsDirectory stringByAppendingPathComponent:[_files objectAtIndex:indexPath.row]] ];
}

@end
