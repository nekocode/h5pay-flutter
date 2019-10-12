#import "H5payPlugin.h"
#import <h5pay/h5pay-Swift.h>

@implementation H5payPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftH5payPlugin registerWithRegistrar:registrar];
}
@end
