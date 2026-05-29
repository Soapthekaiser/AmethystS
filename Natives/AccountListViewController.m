#import <AuthenticationServices/AuthenticationServices.h>
#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "AFNetworking.h"
#import "LauncherPreferences.h"
#import "UIImageView+AFNetworking.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

@interface AccountListViewController()<ASWebAuthenticationPresentationContextProviding>
@property(nonatomic, strong) NSMutableArray *accountList;
@property(nonatomic) ASWebAuthenticationSession *authVC;
@end

@implementation AccountListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.accountList == nil) {
        self.accountList = [NSMutableArray array];
    } else {
        [self.accountList removeAllObjects];
    }
    NSString *listPath = [NSString stringWithFormat:@"%s/accounts", getenv("POJAV_HOME")];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:listPath error:nil];
    for(NSString *file in files) {
        NSString *path = [listPath stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fm fileExistsAtPath:path isDirectory:(&isDir)];
        if(!isDir && [file hasSuffix:@".json"]) {
            [self.accountList addObject:parseJSONFromFile(path)];
        }
    }
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.accountList.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    if (indexPath.row == self.accountList.count) {
        cell.imageView.image = [UIImage imageNamed:@"IconAdd"];
        cell.textLabel.text = localize(@"login.option.add", nil);
        return cell;
    }
    NSDictionary *selected = self.accountList[indexPath.row];
    cell.textLabel.text = selected[@"username"];
    if (selected[@"xboxGamertag"] == nil) {
        cell.detailTextLabel.text = localize(@"login.option.local", nil);
    } else {
        cell.detailTextLabel.text = selected[@"xboxGamertag"];
    }
    cell.imageView.contentMode = UIViewContentModeCenter;
    [cell.imageView setImageWithURL:[NSURL URLWithString:[selected[@"profilePicURL"] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"]] placeholderImage:[UIImage imageNamed:@"DefaultAccount"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row == self.accountList.count) {
        [self actionAddAccount:cell];
        return;
    }
    self.modalInPresentation = YES;
    self.tableView.userInteractionEnabled = NO;
    id callback = ^(id status, BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self callbackMicrosoftAuth:status success:success forCell:cell];
        });
    };
    [[BaseAuthenticator loadSavedName:self.accountList[indexPath.row][@"username"]] refreshTokenWithCallback:callback];
}

- (void)actionAddAccount:(UITableViewCell *)sender {
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [picker addAction:[UIAlertAction actionWithTitle:localize(@"login.option.microsoft", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { [self actionLoginMicrosoft:sender]; }]];
    [picker addAction:[UIAlertAction actionWithTitle:localize(@"login.option.local", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { [self actionLoginLocal:sender]; }]];
    [picker addAction:[UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    picker.popoverPresentationController.sourceView = sender;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)actionLoginLocal:(UIView *)sender {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:localize(@"Sign in", nil) message:localize(@"login.option.local", nil) preferredStyle:UIAlertControllerStyleAlert];
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = localize(@"login.alert.field.username", nil);
    }];
    [controller addAction:[UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        id callback = ^(id status, BOOL success) { self.whenItemSelected(); [self dismissViewControllerAnimated:YES completion:nil]; };
        [[[LocalAuthenticator alloc] initWithInput:controller.textFields[0].text] loginWithCallback:callback];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)actionLoginMicrosoft:(UITableViewCell *)sender {
    NSURL *url = [NSURL URLWithString:@"https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL&redirect_url=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf"];
    self.authVC = [[ASWebAuthenticationSession alloc] initWithURL:url callbackURLScheme:@"ms-xal-00000000402b5328" completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
        if (callbackURL == nil) return;
        NSDictionary *queryItems = [self parseQueryItems:callbackURL.absoluteString];
        if (queryItems[@"code"]) {
            id callback = ^(id status, BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^(){ [self callbackMicrosoftAuth:status success:success forCell:sender]; });
            };
            [[[MicrosoftAuthenticator alloc] initWithInput:queryItems[@"code"]] loginWithCallback:callback];
        }
    }];
    self.authVC.presentationContextProvider = self;
    [self.authVC start];
}

- (NSDictionary *)parseQueryItems:(NSString *)url {
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSArray<NSURLQueryItem *> *queryItems = [NSURLComponents componentsWithString:url].queryItems;
    for (NSURLQueryItem *item in queryItems) { result[item.name] = item.value; }
    return result;
}

- (void)callbackMicrosoftAuth:(id)status success:(BOOL)success forCell:(UITableViewCell *)cell {
    if (success) {
        self.whenItemSelected();
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        showDialog(localize(@"Error", nil), [status localizedDescription]);
    }
}

#pragma mark - ASWebAuthenticationPresentationContextProviding
- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    return UIApplication.sharedApplication.windows.firstObject;
}

@end
