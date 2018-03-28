#import <Foundation/Foundation.h>
#import "WXAnalyzerDataTransfer.h"
#import "WXAnalyzerProtocol.h"
#import "WXUtility.h"
#import "WXHandlerFactory.h"

@implementation WXAnalyzerDataTransfer

//+ (void)transDataAfterDownLoad:(WXSDKInstance *)instance
//{
//    if (![self hasAnalyzer] || NULL == instance) {
//        return;
//    }
//
//    [self transMeasureValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                    withKey:JSTEMPLATESIZE withValue:instance.performanceDict[JSTEMPLATESIZE]];
//    [self transMeasureValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                    withKey:NETWORKTIME withValue:instance.performanceDict[NETWORKTIME]];
//
//    [self transDimenValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                    withKey:CACHETYPE withValue:instance.performanceDict[CACHETYPE]];
//    [self transDimenValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                  withKey:WXREQUESTTYPE withValue:instance.performanceDict[WXREQUESTTYPE]];
//    [self transDimenValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                  withKey:NETWORKTYPE withValue:instance.performanceDict[NETWORKTYPE]];
//    [self transDimenValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                  withKey:PAGENAME withValue:instance.performanceDict[PAGENAME]];
//
//}
//
//+(void) transDataAfterFirstScreen:(WXSDKInstance *)instance
//{
//    if (![self hasAnalyzer] || NULL == instance) {
//        return;
//    }
//
//    [self transMeasureValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                    withKey:FSRENDERTIME withValue:instance.performanceDict[FSRENDERTIME]];
//    [self transMeasureValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                    withKey:JSLIBINITTIME withValue:instance.performanceDict[JSLIBINITTIME]];
//    [self transMeasureValue:instance.instanceId withUrl:[instance.scriptURL absoluteString]
//                    withKey:JSLIBINITTIME withValue:instance.performanceDict[JSLIBINITTIME]];
//
//
//}
//
//+(void) transDataAfterExit:(WXSDKInstance *)instance
//{
//    if (![self hasAnalyzer] || NULL == instance) {
//        return;
//    }
//}

+(void) transDimenValue:(NSString *)instansId withUrl:(NSString *)url withKey:key withValue:(id)value
{
    if (![self hasAnalyzer]) {
        return;
    }
    NSDictionary *dic= @{
                         @"instanceId":instansId,
                         @"url":url,
                         key:value
                         };
    NSString *jsonData =[WXUtility JSONString:dic];
    [self _transDataToAnaylzer:GROUP_ANALYZER withModule:MODULE_PERFORMANCE withType:@"dimen_real_time" jsonData:jsonData];
}

+(void) transMeasureValue:(NSString *)instansId withUrl:(NSString *)url withKey:key withValue:(id)value
{
    if (![self hasAnalyzer]) {
        return;
    }
    NSDictionary *dic= @{
                         @"instanceId":instansId,
                         @"url":url,
                         key:value
                         };
    NSString *jsonData =[WXUtility JSONString:dic];
    [self _transDataToAnaylzer:GROUP_ANALYZER withModule:MODULE_PERFORMANCE withType:@"measure_real_time" jsonData:jsonData];
}

+(void)transErrorInfo:(WXJSExceptionInfo *)errorInfo
{
    if (![self hasAnalyzer]) {
        return;
    }
    
    NSDictionary *dic= @{
                         @"instanceId":errorInfo.instanceId,
                         @"url":errorInfo.bundleUrl,
                         @"errorCode":errorInfo.errorCode,
                         @"errorGroup":@"",
                         @"errorMsg":errorInfo.exception
                         };
    
    NSString *jsonData =[WXUtility JSONString:dic];
    [self _transDataToAnaylzer:GROUP_ANALYZER withModule:MODULE_ERROR withType:@"js" jsonData:jsonData];
}


+ (void) _transDataToAnaylzer:(NSString *)group withModule:(NSString*)module withType:(NSString *)type jsonData:(NSString *)jsonData
{
    NSLog(@"test -> transDataToAnaylzer module%@,withType:%@,jsonData:%@",module,type,jsonData);
    NSMutableArray* analyzerList = [WXHandlerFactory getAnalyzerList];
    if (nil == analyzerList || analyzerList.count <= 0) {
        return;
    }
    NSDictionary* dic = @{
                          @"group":group,
                          @"module":module,
                          @"type":type,
                          @"data":jsonData
                          };
    
    for (id analyzer in analyzerList) {
        if ( [analyzer respondsToSelector:(@selector(transfer:))])
        {
            [analyzer performSelector:@selector(transfer:) withObject:dic];
        }
        
    }
}

+ (BOOL) hasAnalyzer
{
    return true;
}

@end
