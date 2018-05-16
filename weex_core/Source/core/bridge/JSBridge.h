//
//  JSBridge.h
//  WeexSDK
//
//  Created by 陈佩翰 on 2018/5/16.
//  Copyright © 2018年 taobao. All rights reserved.
//

#ifndef JSBridge_h
#define JSBridge_h

#include "WXTypeDefine.h"
#include <map>


namespace WeexCore {
    
    //typedef void(*JSExceptionHandler)(int32_t runTimeId,int32_t contextId,char* exception,std::map<char*,char*> extInfos);
    
    
    class JSBridge{
        
    protected:
        JSBridge(){}
    public:
        virtual bool createJSRunTime        (int32_t runTimeId, char *params)=0;
        virtual bool destroyJSRunTime       (int32_t runTimeId)=0;
        
        virtual bool createJSContext        (int32_t runTimeId,int32_t contextId) =0;
        virtual bool destoryJSContext       (int32_t runTimeId,int32_t contextId) =0;
        
        virtual WXValue callJSMethod        (int32_t runTimeId, int32_t contextId,char *methodName,WXValue args[])=0;
        virtual WXValue execNative          (int32_t runTimeId, int32_t contextId,char *args)=0;
        virtual WXValue executeJavascript   (int32_t runTimeId, int32_t contextId,char *script)=0;
        
        virtual bool setJSVale              (int32_t runTimeId,int32_t contextId,char* name,WXValue value)=0;
        virtual bool getJSVale              (int32_t runTimeId,int32_t contextId,char* name,WXValue value)=0;
        
        virtual void reigsterJSFunc         (int32_t runTimeId,int32_t contextId,WXFuncSignature func)=0;
        
        
       // virtual JSExceptionHandler getJSExceptionHandler ()=0;
        void reportJSException(int32_t runTimeId,int32_t contextId,char* exception,std::map<char*,char*> extInfos);
        
    };
}


#endif /* JSBridge_h */
