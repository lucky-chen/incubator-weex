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
#ifndef jsc_context_ios_h
#define jsc_context_ios_h

#include <core/js_engin/base_js_context.h>
#include "jsc_runtime_ios.h"

namespace WeexCore {
    class JSCContextIOS: public BaseJSContext{
    protected:
        uint32_t contextId;
    public:
        ~JSCContextIOS();
    public:
    
        void onInit(uint32_t contextId,void* impl, JSCRunTimeIOS* runTime);
        
    public:
        void execJSMethod(char *methodName, wson_buffer *args);
        
        wson_buffer *execJSMethodWithResult(char *methodName, wson_buffer *args);
        
        bool executeJavascript(char *script);
        
        void reigsterJSVale(char *name, wson_buffer *valuse);
        
        wson_buffer *getJSVale(char *name);
        
        void reigsterJSFunc(wson_buffer *func);
        
        uint32_t getContextId();
        
        BaseJSRunTime* getJsRunTime();

    };
}


#endif /* jsc_context_ios_h */