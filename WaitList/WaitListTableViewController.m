//
//  WaitListTableViewController.m
//  WaitList
//
//  Created by Developer on 3/6/14.
//  Copyright (c) 2014 AST. All rights reserved.
//

#import "WaitListTableViewController.h"

#import "GuestService.h"
#import "Guest.h"
#import "GuestCell.h"
#import "AddGuestTableViewController.h"
#import "MultipeerConnectivityService.h"

#import "UIColor+Grayscale.h"

#import "BeaconAdvertisingService.h"

@implementation UITableView (TintColor)

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [UIView animateWithDuration:0.3 animations:^{
        if (self.tintAdjustmentMode == UIViewTintAdjustmentModeDimmed) {
            self.backgroundView.backgroundColor = [self.backgroundView.backgroundColor grayscale];
        } else {
            self.backgroundView.backgroundColor = [UIColor colorWithRed:252.0/255.0 green:237.0/255.0 blue:224.0/255.0 alpha:1];
        }
    }];
}

@end

@implementation UINavigationBar (TintColor)

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [UIView animateWithDuration:0.3 animations:^{
        if (self.tintAdjustmentMode == UIViewTintAdjustmentModeDimmed) {
            self.barTintColor = [self.barTintColor grayscale];
            self.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        } else {
            self.barTintColor = [UIColor colorWithRed:231.0/255.0 green:113.0/255.0 blue:37.0/255.0 alpha:1];
            self.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorWithRed:252.0/255.0 green:234.0/255.0 blue:218.0/255.0 alpha:1]};
        }
    }];
}

@end


@interface WaitListTableViewController () <UIAlertViewDelegate, AddGuestDelegate, UIActionSheetDelegate, MultipeerConnecivityServiceDelegate> {
    NSDateFormatter *_arrivalDateFormatter;
    Guest *_selectedGuest;
    NSIndexPath *_selectedIndexPath;
    
    UIBarButtonItem *_addGuestButtonItem;
    UIBarButtonItem *_startBeaconButtonItem;
    UIBarButtonItem *_stopBeaconButtonItem;
}

@end

@implementation WaitListTableViewController

- (void)dealloc {
    [[BeaconAdvertisingService sharedInstance] removeObserver:self forKeyPath:@"advertising"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *tableBgView = [[UIView alloc] initWithFrame:self.view.frame];
    tableBgView.backgroundColor = [UIColor colorWithRed:252.0/255.0 green:237.0/255.0 blue:224.0/255.0 alpha:1];
    self.tableView.backgroundView = tableBgView;

    _addGuestButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGuestButtonTouched:)];
    _startBeaconButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Welcome" style:UIBarButtonItemStylePlain target:self action:@selector(startAdvertising)];
    _stopBeaconButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Stop Beacon" style:UIBarButtonItemStylePlain target:[BeaconAdvertisingService sharedInstance] action:@selector(stopAdvertising)];

    [[BeaconAdvertisingService sharedInstance] addObserver:self forKeyPath:@"advertising" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self updateAdvertiseButton];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"advertising"]) {
        [self updateAdvertiseButton];
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[MultipeerConnectivityService sharedService] advertiseWithName:@"Host Stand"];
    [MultipeerConnectivityService sharedService].delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)startAdvertising {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Beacon" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Core Cupcakes", @"@synthesize salads", @"Weak Wraps", @"Bitmask Bites", nil];
    [actionSheet setTintColor:[UIColor colorWithRed:231.0/255.0 green:113.0/255.0 blue:37.0/255.0 alpha:1]];
    [actionSheet showFromBarButtonItem:_startBeaconButtonItem animated:YES];
}

- (IBAction)addGuestButtonTouched:(id)sender {
    UINavigationController *addGuestForm = [[self storyboard] instantiateViewControllerWithIdentifier:@"AddGuestForm"];
    [addGuestForm setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:addGuestForm animated:YES completion:nil];
    AddGuestTableViewController *addGuestTableViewController = (AddGuestTableViewController *)addGuestForm.topViewController;
    addGuestTableViewController.delegate = self;
}

- (void)updateAdvertiseButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([BeaconAdvertisingService sharedInstance].isAdvertising) {
            self.navigationItem.rightBarButtonItems = @[_addGuestButtonItem, _stopBeaconButtonItem];
        } else {
            self.navigationItem.rightBarButtonItems = @[_addGuestButtonItem, _startBeaconButtonItem];
        }
    });
}

- (IBAction)setMessageButtonTouched:(id)sender {
    
}

- (void)guestAdded:(Guest *)guest atIndex:(NSInteger)index {
    [self.tableView beginUpdates];
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Guest *guest = [GuestService sharedInstance].guests[indexPath.row];
    _selectedGuest = guest;
    _selectedIndexPath = indexPath;
    UIAlertView *seatGuestAlertView = [[UIAlertView alloc] init];
    [seatGuestAlertView setTitle:guest.name];
    [seatGuestAlertView setMessage:guest.notes];
    [seatGuestAlertView setCancelButtonIndex:3];
    [seatGuestAlertView addButtonWithTitle:@"Seat"];
    [seatGuestAlertView addButtonWithTitle:@"Edit"];
    [seatGuestAlertView addButtonWithTitle:@"E-mail Notification"]; // include a e-mail notification list. That I'm working on
    [seatGuestAlertView addButtonWithTitle:@"Cancel"];
    [seatGuestAlertView setDelegate:self];
    [seatGuestAlertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 || buttonIndex == 2) { // seat or remove
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [[GuestService sharedInstance] removeGuest:_selectedGuest];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    } else if (buttonIndex == 1) { // Edit
        UINavigationController *addGuestForm = [[self storyboard] instantiateViewControllerWithIdentifier:@"AddGuestForm"];
        [addGuestForm setModalPresentationStyle:UIModalPresentationFormSheet];
        [self presentViewController:addGuestForm animated:YES completion:nil];
        AddGuestTableViewController *addGuestTableViewController = (AddGuestTableViewController *)addGuestForm.topViewController;
        addGuestTableViewController.guest = _selectedGuest;
        addGuestTableViewController.delegate = self;

    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[GuestService sharedInstance] guests] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *HeaderCellIdentifier = @"Header";
    UITableViewCell *headerCell = [tableView dequeueReusableCellWithIdentifier:HeaderCellIdentifier];
    return headerCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *GuestCellIdentifier = @"Guest";
    GuestCell *cell = [tableView dequeueReusableCellWithIdentifier:GuestCellIdentifier forIndexPath:indexPath];
    Guest *guest = [GuestService sharedInstance].guests[indexPath.row];
    
    if (indexPath.row % 2) {
        cell.evenRow = YES;
    } else {
        cell.evenRow = NO;
    }
    
    // Configure the cell...
    cell.guest = guest;
    cell.numberLabel.text = [NSString stringWithFormat:@"%d", indexPath.row+1];
    
    return cell;
}

#pragma mark - MultipeerConnecivityServiceDataReceptionDelegate Methods

- (void)didChangeState:(MCSessionState)state forPeer:(MCPeerID *)peerId {
    NSLog(@"State Changed: %d for Peer: %@", state, peerId.displayName);
}

- (void)didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerId {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *guestInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        Guest *guest = [[Guest alloc] init];
        guest.name = [NSString stringWithFormat:@"%@ (SA)", guestInfo[@"name"]];
        guest.partySize = [guestInfo[@"partySize"] integerValue];
        guest.arrivalTime = [NSDate date];
        guest.quotedTime = @(5);
        guest.mood = 0;
        guest.notes = @"Added self to list";
        NSInteger index = [[GuestService sharedInstance] addGuest:guest];
        [self guestAdded:guest atIndex:index];
    });
}

#pragma mark - Aciton sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            NSUUID *cupcakesUUID = [[NSUUID alloc] initWithUUIDString:@"EC6F3659-A8B9-4434-904C-A76F788DAC43"];
            [[BeaconAdvertisingService sharedInstance] startAdvertisingUUID:cupcakesUUID major:0 minor:0];
            self.navigationItem.title = @"Core Cupcakes";
            break;
        } case 1: {
            NSUUID *saladsUUID = [[NSUUID alloc] initWithUUIDString:@"7B377E4A-1641-4765-95E9-174CD05B6C79"];
            [[BeaconAdvertisingService sharedInstance] startAdvertisingUUID:saladsUUID major:0 minor:0];
            self.navigationItem.title = @"@synthesize salads";
            break;
        } case 2: {
            NSUUID *wrapsUUID = [[NSUUID alloc] initWithUUIDString:@"2B144D35-5BA6-4010-B276-FC4D4845B292"];
            [[BeaconAdvertisingService sharedInstance] startAdvertisingUUID:wrapsUUID major:0 minor:0];
            self.navigationItem.title = @"Weak Wraps";
            break;
        } case 3: {
            NSUUID *bitesUUID = [[NSUUID alloc] initWithUUIDString:@"A456AF8C-CD6C-4AA8-9AD5-4C8D9C1939D3"];
            [[BeaconAdvertisingService sharedInstance] startAdvertisingUUID:bitesUUID major:0 minor:0];
            self.navigationItem.title = @"Bitmask Bites";
            break;
        }
        default:
            break;
    }
}

@end
