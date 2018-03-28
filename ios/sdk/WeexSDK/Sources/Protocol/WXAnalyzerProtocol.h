#import <Foundation/Foundation.h>
#import "WXAppMonitorProtocol.h"

#define GROUP_ANALYZER @"WXAnalyzer"
#define MODULE_PERFORMANCE @"WXPerformance"
#define MODULE_ERROR @"WXError"

@protocol WXAnalyzerProtocol <NSObject>


@required
/**
 @param value  = @{
                    @"group":group,
                    @"module":module,
                    @"type":type,
                    @"data":jsonData
                };
 */
- (void)transfer:(NSDictionary *) value;

@end
