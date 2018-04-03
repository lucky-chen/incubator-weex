#import <Foundation/Foundation.h>
#import "WXAnalyzerCenter.h"
#import "WXAnalyzerProtocol.h"
#import "WXAppMonitorProtocol.h"
#import "WXSDKManager.h"
#import "WXLog.h"
#import "WXTracingManager.h"
#import "WXAnalyzerCenter.h"
#import "WXAnalyzerCenter+Transfer.h"

@interface WXAnalyzerCenter ()
@property (nonatomic, strong) NSMutableArray<WXAnalyzerProtocol> *analyzerList;
@end

@implementation WXAnalyzerCenter

+ (instancetype) sharedInstance{

    static WXAnalyzerCenter *instance = nil;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        instance = [[WXAnalyzerCenter alloc] init];
        instance.analyzerList= [NSMutableArray<WXAnalyzerProtocol> new];
    });

    return instance;
}

+ (void) transDataOnState:(CommitState) timeState withInstaneId:(NSString *)instanceId data:(NSDictionary *)data
{
//    if(![self needTransfer] || !instanceId){
//        return;
//    }
#ifndef DEBUG
    return;
#endif
    if (!instanceId) {
        return;
    }
    WXSDKInstance * instance = [WXSDKManager instanceForID:instanceId];
    if (!instance) {
        return;
    }
    WXLogDebug(@"test --> transDataOnState :%ld",timeState);

    NSDictionary *commitDimenKeys = [self getKeys:TRUE];
    NSDictionary *commitMeasureKeys = [self getKeys:FALSE];
    for(id key in data){
       if([self checkDataWithSate:timeState checkKey:key limitDic:commitMeasureKeys]){
           [self _transMeasureValue:instance key:key withVal:[data valueForKey:key]];
       }else if([self checkDataWithSate:timeState checkKey:key limitDic:commitDimenKeys]){
           [self _transDimenValue:instance key:key withVal:[data valueForKey:key]];
       }else{
          // WXLogDebug(@"WXAnalyzerDataTransfer -> unKnowPerformanceKey :%@",key);
       }
    }
}

+(BOOL) checkDataWithSate:(CommitState)timeState checkKey:(id)key limitDic:(NSDictionary *)limitDic
{
    if (!key || ![key isKindOfClass:[NSString class]]) {
        return FALSE;
    }
   
    if (![limitDic objectForKey:key]) {
        return FALSE;
    }
    CommitState limitSate = [[limitDic objectForKey:key] intValue];
    if (timeState != limitSate) {
        return FALSE;
    }
    return TRUE;
}

+ (NSDictionary *) getKeys:(BOOL) measureOrDimen
{
    static NSDictionary *commitDimenKeys;
    static NSDictionary *commitMeasureKeys;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // non-standard perf commit names, remove this hopefully.
        
        commitDimenKeys =@{
                           BIZTYPE:             [NSNumber numberWithInt:DebugAfterFSFinish],
                           PAGENAME:            [NSNumber numberWithInt:DebugAfterRequest],
                           WXSDKVERSION:        [NSNumber numberWithInt:DebugAfterRequest],
                           JSLIBVERSION:        [NSNumber numberWithInt:DebugAfterRequest],
                           JSLIBSIZE:           [NSNumber numberWithInt:DebugAfterRequest],
                           WXREQUESTTYPE:       [NSNumber numberWithInt:DebugAfterRequest],
                           WXCONNECTIONTYPE:    [NSNumber numberWithInt:DebugAfterRequest],
                           NETWORKTYPE:         [NSNumber numberWithInt:DebugAfterRequest],
                           CACHETYPE:           [NSNumber numberWithInt:DebugAfterRequest],
                           WXCUSTOMMONITORINFO: [NSNumber numberWithInt:DebugAfterRequest]
        };
        commitMeasureKeys =@{
                             SDKINITTIME:                   [NSNumber numberWithInt:DebugAfterFSFinish],
                             SDKINITINVOKETIME:             [NSNumber numberWithInt:DebugAfterFSFinish],
                             JSLIBINITTIME:                 [NSNumber numberWithInt:DebugAfterFSFinish],
                             JSTEMPLATESIZE:                [NSNumber numberWithInt:DebugAfterRequest],
                             NETWORKTIME:                   [NSNumber numberWithInt:DebugAfterRequest],
                             COMMUNICATETIME:               [NSNumber numberWithInt:DebugAfterExist],
                             SCREENRENDERTIME:              [NSNumber numberWithInt:DebugAfterExist],
                             TOTALTIME:                     [NSNumber numberWithInt:DebugAfterExist],
                             FIRSETSCREENJSFEXECUTETIME:    [NSNumber numberWithInt:DebugAfterFSFinish],
                             CALLCREATEINSTANCETIME:        [NSNumber numberWithInt:DebugAfterFSFinish],
                             COMMUNICATETOTALTIME:          [NSNumber numberWithInt:DebugAfterExist],
                             FSRENDERTIME:                  [NSNumber numberWithInt:DebugAfterExist],
                             COMPONENTCOUNT:                [NSNumber numberWithInt:DebugAfterExist],
                             CACHEPROCESSTIME:              [NSNumber numberWithInt:DebugAfterRequest],
                             CACHERATIO:                    [NSNumber numberWithInt:DebugAfterRequest],
                             M_FS_CALL_JS_TIME:             [NSNumber numberWithInt:DebugAfterFSFinish],
                             M_FS_CALL_JS_NUM:              [NSNumber numberWithInt:DebugAfterFSFinish],
                             M_FS_CALL_NATIVE_TIME:         [NSNumber numberWithInt:DebugAfterFSFinish],
                             M_FS_CALL_NATIVE_NUM:          [NSNumber numberWithInt:DebugAfterFSFinish],
                             M_FS_CALL_EVENT_NUM:           [NSNumber numberWithInt:DebugAfterFSFinish],
                             M_CELL_EXCEED_NUM:             [NSNumber numberWithInt:DebugAfterFSFinish],
                             M_MAX_DEEP_VDOM:               [NSNumber numberWithInt:DebugAfterExist],
                             M_IMG_WRONG_SIZE_NUM:          [NSNumber numberWithInt:DebugAfterExist],
                             M_TIMER_NUM:                   [NSNumber numberWithInt:DebugAfterFSFinish]
                             };
        
    });
    return measureOrDimen?commitMeasureKeys:commitDimenKeys;
}

+ (void) _transMeasureValue:(WXSDKInstance *)instance key:(NSString *)commitKey withVal:(id)commitVal
{
    [self _transDataToAnaylzer:instance
                        withModule:MODULE_PERFORMANCE
                        withType:TYPE_MEASURE_REAL
                        withData:@{commitKey:commitVal}
     ];
}

+ (void) _transDimenValue:(WXSDKInstance *)instance key:(NSString *)commitKey withVal:(id)commitVal
{
    [self _transDataToAnaylzer:instance
                        withModule:MODULE_PERFORMANCE
                        withType:TYPE_DIMEN_REAL
                        withData:@{commitKey:commitVal}
     ];
}

+(void) _transDataToAnaylzer:(WXSDKInstance *)instance withModule:(NSString *)module  withType:(NSString *)type withData:(NSDictionary *)data
{
    
    //    NSString *jsonData =[WXUtility JSONString:dic];
    //    jsonData = [jsonData stringByReplacingOccurrencesOfString:@"\n" withString:@""];\\
    
    NSMutableDictionary *wrapDic = [data mutableCopy];
    [wrapDic setObject:instance.instanceId forKey:@"instanceId"];
    [wrapDic setObject:[instance.scriptURL absoluteString] forKey:@"url"];
    
    
    NSMutableArray* analyzerList = [self getAnalyzerList];
    if (nil == analyzerList) {
        return;
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:GROUP_ANALYZER forKey:@"group"];
    [dic setValue:module forKey:@"module"];
    [dic setValue:type forKey:@"type"];
    for (id key in data)
    {
        [dic setValue:data[key] forKey:key];
    }
    [dic setValue:instance.instanceId forKey:@"instanceId"];
    [dic setValue:[instance.scriptURL absoluteString] forKey:@"url"];

    WXLogInfo(@"WXPerformance :%@",dic);
    
    for (id analyzer in analyzerList) {
        if ( [analyzer respondsToSelector:(@selector(transfer:))])
        {
            [analyzer performSelector:@selector(transfer:) withObject:dic];
        }
    }
}

+(void)transErrorInfo:(WXJSExceptionInfo *)errorInfo
{
    if (!errorInfo) {
        return;
    }
    WXSDKInstance *instance = [WXSDKManager instanceForID:errorInfo.instanceId];
    if (!instance) {
        return;
    }
    NSDictionary *dic= @{
                         @"errorCode":errorInfo.errorCode,
                         @"errorGroup":@"",
                         @"errorMsg":errorInfo.exception
                         };
    
    [self _transDataToAnaylzer:instance
                    withModule:MODULE_ERROR
                      withType:TYPE_JS_ERROR
                      withData:dic
     ];
}

+ (void) addWxAnalyzer:(id<WXAnalyzerProtocol>)handler
{
    if (!handler) {
        return;
    }
    [[WXAnalyzerCenter sharedInstance].analyzerList addObject:handler];
}

+ (void) rmWxAnalyzer:(id<WXAnalyzerProtocol>)handler
{
    if (!handler) {
        return;
    }
    [[WXAnalyzerCenter sharedInstance].analyzerList removeObject:handler];
}

+ (NSMutableArray<WXAnalyzerProtocol> *)getAnalyzerList
{
    return [WXAnalyzerCenter sharedInstance].analyzerList;
}

+(BOOL) needTransfer
{
    NSMutableArray* analyzerList = [self getAnalyzerList];
    if (nil == analyzerList || analyzerList.count <= 0) {
        return FALSE;
    }
    return TRUE;
}

@end
