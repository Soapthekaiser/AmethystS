#import "LauncherProfilesViewController.h"
#import "LauncherPreferences.h"
#import "LauncherPrefGameDirViewController.h"
#import "PLProfiles.h"
#import "UIKit+AFNetworking.h"
#import "utils.h"

@interface LauncherProfilesViewController ()
@property(nonatomic) UIBarButtonItem *createButtonItem;
@end

@implementation LauncherProfilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [PLProfiles updateCurrent];
    [self.tableView reloadData];
}

- (void)setupInstanceCell:(UITableViewCell *) cell atRow:(NSInteger)row {
    cell.userInteractionEnabled = YES;
    if (row == 0) {
        cell.imageView.image = [UIImage systemImageNamed:@"folder"];
        cell.textLabel.text = localize(@"preference.title.game_directory", nil);
        cell.detailTextLabel.text = getPrefObject(@"general.game_directory");
    }
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    if (indexPath.section == 0) {
        [self setupInstanceCell:cell atRow:indexPath.row];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 1; }

@end
