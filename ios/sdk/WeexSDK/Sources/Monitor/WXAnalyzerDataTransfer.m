#import <Foundation/Foundation.h>
#import "WXAnalyzerDataTransfer.h"
#import "WXAnalyzerProtocol.h"
#import "WXUtility.h"
#import "WXTracingManager.h"
#import "WXLog.h"
#import "WXSDKManager.h"

@implementation WXAnalyzerDataTransfer


+ (void) transData:(WXSDKInstance *)instance withState:(WXPerformanceState)state
{
    if(![self needTransfer])
    {
        return;
    }
    switch (state) {
        case AfterRequest:
            [self transDataAfterRequest:instance];
            break;
        case AfterCreateFinish:
            [self transDataAfterCreateFinsh:instance];
            break;
        case AfterExit:
            [self transDataAfterExit:instance];
            break;
        default:
            WXLogDebug(@"unknow WXPerformanceState :%ld",state);
            break;
    }
}

+ (void) transDataAfterRequest:(WXSDKInstance *)instance
{
    
}

+ (void) transDataAfterCreateFinsh:(WXSDKInstance *)instance
{
    
}

+ (void) transDataAfterExit:(WXSDKInstance *)instance
{
    
}




+(BOOL) needTransfer
{
    return true;
}

+ (void) transDimenValueWithInstanceId:(NSString *)instansId data:(NSDictionary *)data
{
    if (![self needTransfer]) {
        return;
    }
 
    
    
    
//    NSString *jsonData =[WXUtility JSONString:dic];
//    jsonData = [jsonData stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    [self _transDataToAnaylzer:GROUP_ANALYZER withModule:MODULE_PERFORMANCE withType:@"dimen_real_time" data];
}

+ (void) transMeasureValueWithInstanceId:(NSString*)instansId url:(NSString *)url data:(NSDictionary *)data
{
    if (![self needTransfer]) {
        return;
    }
    NSMutableDictionary *dic = [data mutableCopy];
    [dic setValue:instansId forKey:@"instanceId"];
    [dic setValue:url forKey:@"url"];
    NSInteger tag = [data[@"tag"] integerValue];
    NSString *jsonData =[WXUtility JSONString:dic];
    jsonData = [jsonData stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    [self _transDataToAnaylzer:GROUP_ANALYZER withModule:MODULE_PERFORMANCE withType:@"measure_real_time" tag:tag jsonData:jsonData];
}

+(void)transErrorInfo:(WXJSExceptionInfo *)errorInfo
{
    NSDictionary *dic= @{
                         @"instanceId":errorInfo.instanceId,
                         @"url":errorInfo.bundleUrl,
                         @"errorCode":errorInfo.errorCode,
                         @"errorGroup":@"",
                         @"errorMsg":errorInfo.exception
                         };
    
    NSString *jsonData =[WXUtility JSONString:dic];
    jsonData = [jsonData stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    [self _transDataToAnaylzer:GROUP_ANALYZER withModule:MODULE_ERROR withType:@"js" jsonData:jsonData];
}

+ (void) _transDataToAnaylzer:(NSString *)group withModule:(NSString*)module withType:(NSString *)type jsonData:(NSString *)jsonData{
    [self _transDataToAnaylzer:GROUP_ANALYZER withModule:MODULE_ERROR withType:@"js" tag:NSIntegerMax jsonData:jsonData];
}

+ (void) _transDataToAnaylzer:(NSString *)group withModule:(NSString*)module withType:(NSString *)type withValue:(NSDictionary *) dic
{
    NSLog(@"test -> transDataToAnaylzer module%@,withType:%@,jsonData:%@",module,type,jsonData);
    NSMutableArray* analyzerList = [WXTracingManager getAnalyzerList];
    if (nil == analyzerList || analyzerList.count <= 0) {
        return;
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:group forKey:@"group"];
    [dic setValue:module forKey:@"module"];
    [dic setValue:type forKey:@"type"];
    [dic setValue:jsonData forKey:@"data"];
    if (tag!= NSIntegerMax) {
        [dic setValue:@(tag) forKey:@"tag"];
    }
    
    for (id analyzer in analyzerList) {
        if ( [analyzer respondsToSelector:(@selector(transfer:))])
        {
            [analyzer performSelector:@selector(transfer:) withObject:dic];
        }
    }
}


@end
