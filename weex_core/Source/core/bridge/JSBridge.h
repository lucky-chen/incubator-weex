/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
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
        virtual bool callCreateJSRunTime        (uint32_t runTimeId, std::map<std::string,std::string> &params)=0;
        virtual bool callDestroyJSRunTime       (uint32_t runTimeId)=0;
        
        virtual bool callCreateJSContext        (uint32_t runTimeId,uint32_t contextId) =0;
        virtual bool callDestoryJSContext       (uint32_t runTimeId,uint32_t contextId) =0;
        
        virtual WXValue callJSMethod        (uint32_t runTimeId, uint32_t contextId,char *methodName,WXValue args[],uint8_t argsLength)=0;
        virtual WXValue callExecNative          (uint32_t runTimeId, uint32_t contextId,WXValue args[],uint8_t argsLength)=0;
        virtual WXValue callExecuteJavascript   (uint32_t runTimeId, uint32_t contextId,char *script)=0;
        
        virtual bool callReigsterJSVale              (uint32_t runTimeId,uint32_t contextId,char* name,WXValue value)=0;
        virtual bool callGetJSVale              (uint32_t runTimeId,uint32_t contextId,char* name,WXValue value)=0;
        
        virtual void callReigsterJSFunc         (uint32_t runTimeId,uint32_t contextId,WXFuncSignature func)=0;
        
        
       // virtual JSExceptionHandler getJSExceptionHandler ()=0;
        void onReportJSException(int32_t runTimeId,int32_t contextId,char* exception,std::map<std::string,std::string> &extInfos);
        
    };
}


#endif /* JSBridge_h */
