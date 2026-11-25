#import <Preferences/PSListController.h>

@interface NDRootListController : PSListController
@end

@implementation NDRootListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}
@end
