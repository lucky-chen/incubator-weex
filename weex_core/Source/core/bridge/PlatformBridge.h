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
//  PlatformBridge.hpp
//  Pods-WeexDemo
//
//  Created by 陈佩翰 on 2018/5/17.
//

#ifndef PlatformBridge_hpp
#define PlatformBridge_hpp

#include <core/bridge/PlatformBridge.h>
#include <core/bridge/RenderBridge.h>
#include <core/api/WXTypeDefine.h>

namespace WeexCore {
    
    enum InstanceState{
        ON_CREATE,
        ON_BACK,
        ON_DESTORY
    };
    
    enum ExceptionType{
        JS_EXCEPTION,
        NATIVE_CORE_EXCEPTION
    };
    
    class PlatformBridge{
    protected:
        PlatformBridge(){}
    public:
        
        //impl by platform
        virtual WeexCore::WXValue onCallNative(const char* instanceId,const char* task,const char* callBack) = 0;
        virtual WeexCore::WXValue onCallNativeModule(const char* instanceId, const char *module, const char *method,
                                                     const char *argString, const char *optString) = 0;
        virtual WeexCore::WXValue onnCallNativeComponent(const char* pageId, const char* ref, const char *method,
                                       const char *argString, const char *optString)=0;
        
        virtual void onReportException(ExceptionType exceptionType,const char* instanceId,const char* func,const char* exception)=0;
        
        virtual void onSetTimeOut(const char* instanceId,const char* callBackId,const char* time) =0;
        virtual void onRemoveimer(const char* instanceId)=0;
        
        //api of weexCore
        void callInitWeexCore(const char* frameWork,WeexCore::RenderBridge *renderBridge,std::map<char*,char*> params);
        
        void callInstanceStateChanged(const char* instanceId, InstanceState state,std::map<char*,char*> infos);
        void callRegisterCoreEnv(const char *instanceId,char* key,char* value);
        
        WeexCore::WXValue callJSMethod(const char* instanceId,const char *methodName,WeexCore::WXValue *arg);
        void callExecuteJavascript(const char *stript,WeexCore::WXValue *arg);
        
        void callUpdateGlobalConfig(const char* config);
        
    };
}

#endif /* PlatformBridge_hpp */
