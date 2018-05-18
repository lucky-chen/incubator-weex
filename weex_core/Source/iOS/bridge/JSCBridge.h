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
//  JSCBridge.hpp
//  Pods-WeexDemo
//
//  Created by 陈佩翰 on 2018/5/18.
//

#ifndef JSCBridge_hpp
#define JSCBridge_hpp

#include <core/bridge/JSBridge.h>


namespace WeexCore {
    class JSCBridge:public JSBridge{
    public:
        JSCBridge(){}
        ~JSCBridge(){}
    public:
        bool callCreateJSRunTime        (uint32_t runTimeId, std::map<std::string,std::string> &params);
        bool callDestroyJSRunTime       (uint32_t runTimeId);
        
        bool callCreateJSContext        (uint32_t runTimeId,uint32_t contextId);
        bool callDestoryJSContext       (uint32_t runTimeId,uint32_t contextId);
        
        WXValue callJSMethod            (uint32_t runTimeId, uint32_t contextId,char *methodName,WXValue args[],uint8_t argsLength);
        WXValue callExecNative          (uint32_t runTimeId, uint32_t contextId,WXValue args[],uint8_t argsLength);
        WXValue callExecuteJavascript   (uint32_t runTimeId, uint32_t contextId,char *script);
        
        bool callReigsterJSVale          (uint32_t runTimeId,uint32_t contextId,char* name,WXValue value);
        bool callGetJSVale               (uint32_t runTimeId,uint32_t contextId,char* name,WXValue value);
        
        void callReigsterJSFunc          (uint32_t runTimeId,uint32_t contextId,WXFuncSignature func);

    };
}

#endif /* JSCBridge_hpp */
