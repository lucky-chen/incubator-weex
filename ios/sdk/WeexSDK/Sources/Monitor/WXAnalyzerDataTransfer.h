
#import <Foundation/Foundation.h>
#import "WXSDKInstance.h"

typedef NS_ENUM(NSUInteger, WXPerformanceState) {
    AfterRequest = 0,
    AfterCreateFinish,
    AfterExit
};


@interface WXAnalyzerDataTransfer :NSObject

+ (void) transData:(NSString *)instanceId withState:(WXPerformanceState) state;

+ (void) transMeasureValueWithInstanceId:(NSString*)instansId data:(NSDictionary *)data;

+ (void) transDimenValueWithInstanceId:(NSString*)instansId data:(NSDictionary *)data;

+ (void) transErrorInfo:(WXJSExceptionInfo *)errorInfo;

+ (BOOL) needTransfer;

@end
