//
//  RenderBridge.h
//  Pods-WeexDemo
//
//  Created by 陈佩翰 on 2018/5/17.
//

#ifndef RenderBridge_h
#define RenderBridge_h
#include <map>
#include <set>
#include <core/layout/style.h>
#include <core/layout/layout.h>

namespace WeexCore {
    class RenderBridge{
    protected:
        RenderBridge(){}
    public:
        
        virtual int onUpdateFinish(const char* pageId, const char *task, const char *callback) = 0;
        
        virtual int onRefreshFinish(const char* pageId, const char *task, const char *callback) = 0;
        
        virtual int onAddEvent(const char* pageId, const char* ref, const char *event) = 0;
        
        virtual int onRemoveEvent(const char* pageId, const char* ref, const char *event) = 0;
        
        virtual int onCreateBody(const char* pageId, const char *componentType, const char* ref,
                                   std::map<std::string, std::string> *styles,
                                   std::map<std::string, std::string> *attributes,
                                   std::set<std::string> *events,
                                   const WXCoreMargin &margins,
                                   const WXCorePadding &paddings,
                                   const WXCoreBorderWidth &borders) = 0;

        virtual int onAddElement(const char* pageId, const char *componentType, const char* ref,
                                   int &index, const char* parentRef,
                                   std::map<std::string, std::string> *styles,
                                   std::map<std::string, std::string> *attributes,
                                   std::set<std::string> *events,
                                   const WXCoreMargin &margins,
                                   const WXCorePadding &paddings,
                                   const WXCoreBorderWidth &borders,
                                   bool willLayout= true) = 0;
        
        virtual int onLayout(const char* pageId, const char* ref,
                               int top, int bottom, int left, int right,
                               int height, int width, int index) = 0;
        
        virtual int onUpdateStyle(const char* pageId, const char* ref,
                                    std::vector<std::pair<std::string, std::string>> *style,
                                    std::vector<std::pair<std::string, std::string>> *margin,
                                    std::vector<std::pair<std::string, std::string>> *padding,
                                    std::vector<std::pair<std::string, std::string>> *border) = 0;
        
        virtual int onUpdateAttr(const char* pageId, const char* ref,
                                   std::vector<std::pair<std::string, std::string>> *attrs) = 0;
        
        virtual int onCreateFinish(const char* pageId) = 0;
        
        virtual int onRemoveElement(const char* pageId, const char* ref) = 0;
        
        virtual int onMoveElement(const char* pageId, const char* ref, const char* parentRef, int index) = 0;

        void callSetStyleWidth(char* instanceId,char *componentRef,float value);

        void callSetStyleHeight(char* instanceId,char *componentRef,float value);

        void callSetMargin(char* instanceId,char *componentRef,int32_t edge,float value);

        void callSetPadding(char* instanceId,char *componentRef,int32_t edge,float value);

        void callSetPosition(char* instanceId,char *componentRef,int32_t edge,float value);

        void callMarkDirty(char* instanceId,char *componentRef,bool dirty);

        void callSetViewPortWidth(char* instanceId,float value);
        
        bool callBindMeasureFunc(const char* componentRef,WXCoreMeasureFunc measureFunc);
        
        void callForceLayout(const char* instanceId);
        bool callNotifyLayout(const char* instanceId);
        
        void callSetDefaultSizeIntoRootDom(const char* instanceId, float defaultWidth, float defaultHeight, bool isWidthWrapContent, bool isHeightWrapContent);
        void callSetRenderContainerWrapContent(const char* instanceId, bool wrap);
       
    };
}

#endif /* RenderBridge_h */
