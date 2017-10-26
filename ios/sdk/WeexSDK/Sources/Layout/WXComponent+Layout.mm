/*
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


#import "WXComponent+Layout.h"
#import "WXComponent_internal.h"
#import "WXTransform.h"
#import "WXAssert.h"
#import "WXSDKInstance_private.h"
#import "WXComponent+BoxShadow.h"

bool flexIsUndefined(float value) {
    return isnan(value);
}

@implementation WXComponent (Layout)

#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

#pragma mark Public

- (void)setNeedsLayout
{
    _isLayoutDirty = YES;
    WXComponent *supercomponent = [self supercomponent];
    if(supercomponent){
        [supercomponent setNeedsLayout];
    }
}

- (BOOL)needsLayout
{
    return _isLayoutDirty;
}

- (CGSize (^)(CGSize))measureBlock
{
    return nil;
}

- (void)layoutDidFinish
{
    WXAssertMainThread();
}

#pragma mark Private

- (void)_initCSSNodeWithStyles:(NSDictionary *)styles
{
#ifndef USE_FLEX
    _cssNode = new_css_node();
    
    _cssNode->print = cssNodePrint;
    _cssNode->get_child = cssNodeGetChild;
    _cssNode->is_dirty = cssNodeIsDirty;
    if ([self measureBlock]) {
        _cssNode->measure = cssNodeMeasure;
    }
    _cssNode->context = (__bridge void *)self;
    
    [self _recomputeCSSNodeChildren];
    [self _fillCSSNode:styles];
    
    // To be in conformity with Android/Web, hopefully remove this in the future.
    if ([self.ref isEqualToString:WX_SDK_ROOT_REF]) {
        if (isUndefined(_cssNode->style.dimensions[CSS_HEIGHT]) && self.weexInstance.frame.size.height) {
            _cssNode->style.dimensions[CSS_HEIGHT] = self.weexInstance.frame.size.height;
        }
        
        if (isUndefined(_cssNode->style.dimensions[CSS_WIDTH]) && self.weexInstance.frame.size.width) {
            _cssNode->style.dimensions[CSS_WIDTH] = self.weexInstance.frame.size.width;
        }
    }
#else
    _flexCssNode = WXCoreFlexLayout::WXCoreLayoutNode::newWXCoreNode();
    if ([self measureBlock]) {
        _flexCssNode->setMeasureFunc(flexCssNodeMeasure);
    }
    _flexCssNode->setContext((__bridge void *)self);
    [self _recomputeCSSNodeChildren];
    [self _fillCSSNode:styles];
    
    if ([self.ref isEqualToString:WX_SDK_ROOT_REF]) {
        if (flexIsUndefined(_flexCssNode->getStyleHeight()) && self.weexInstance.frame.size.height) {
            _flexCssNode->setStyleHeight(self.weexInstance.frame.size.height);
        }
        
        if (flexIsUndefined(_flexCssNode->getStyleWidth()) && self.weexInstance.frame.size.width) {
            _flexCssNode->setStyleWidth(self.weexInstance.frame.size.width);
        }
    }
#endif
}

- (void)_updateCSSNodeStyles:(NSDictionary *)styles
{
    [self _fillCSSNode:styles];
}

-(void)_resetCSSNodeStyles:(NSArray *)styles
{
    [self _resetCSSNode:styles];
}

- (void)_recomputeCSSNodeChildren
{
#ifndef USE_FLEX
    _cssNode->children_count = (int)[self _childrenCountForLayout];
#else
    
#endif
}

- (NSUInteger)_childrenCountForLayout
{
    NSArray *subcomponents = _subcomponents;
    NSUInteger count = subcomponents.count;
    for (WXComponent *component in subcomponents) {
        if (!component->_isNeedJoinLayoutSystem) {
            count--;
        }
    }
    return (int)(count);
}


- (void)_frameDidCalculated:(BOOL)isChanged
{
    WXAssertComponentThread();
    
    if ([self isViewLoaded] && isChanged && [self isViewFrameSyncWithCalculated]) {
        
        __weak typeof(self) weakSelf = self;
        [self.weexInstance.componentManager _addUITask:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf->_transform && !CATransform3DEqualToTransform(strongSelf.layer.transform, CATransform3DIdentity)) {
                // From the UIView's frame documentation:
                // https://developer.apple.com/reference/uikit/uiview#//apple_ref/occ/instp/UIView/frame
                // Warning : If the transform property is not the identity transform, the value of this property is undefined and therefore should be ignored.
                // So layer's transform must be reset to CATransform3DIdentity before setFrame, otherwise frame will be incorrect
                strongSelf.layer.transform = CATransform3DIdentity;
            }
            
            if (!CGRectEqualToRect(strongSelf.view.frame,strongSelf.calculatedFrame)) {
                strongSelf.view.frame = strongSelf.calculatedFrame;
                strongSelf->_absolutePosition = CGPointMake(NAN, NAN);
                [strongSelf configBoxShadow:_boxShadow];
            } else {
                if (![strongSelf equalBoxShadow:_boxShadow withBoxShadow:_lastBoxShadow]) {
                    [strongSelf configBoxShadow:_boxShadow];
                }
            }
            
            [self _resetNativeBorderRadius];
            
            if (strongSelf->_transform) {
                [strongSelf->_transform applyTransformForView:strongSelf.view];
            }
            
            if (strongSelf->_backgroundImage) {
                [strongSelf setGradientLayer];
            }
            [strongSelf setNeedsDisplay];
        }];
    }
}

- (void)_calculateFrameWithSuperAbsolutePosition:(CGPoint)superAbsolutePosition
                           gatherDirtyComponents:(NSMutableSet<WXComponent *> *)dirtyComponents
{
    WXAssertComponentThread();

#ifndef USE_FLEX
    if (!_cssNode->layout.should_update) {
        return;
    }
    _cssNode->layout.should_update = false;
    _isLayoutDirty = NO;
    
    CGRect newFrame = CGRectMake(WXRoundPixelValue(_cssNode->layout.position[CSS_LEFT]),
                                 WXRoundPixelValue(_cssNode->layout.position[CSS_TOP]),
                                 WXRoundPixelValue(_cssNode->layout.dimensions[CSS_WIDTH]),
                                 WXRoundPixelValue(_cssNode->layout.dimensions[CSS_HEIGHT]));
    BOOL isFrameChanged = NO;
    if (!CGRectEqualToRect(newFrame, _calculatedFrame)) {
        isFrameChanged = YES;
        _calculatedFrame = newFrame;
        [dirtyComponents addObject:self];
    }
    
    CGPoint newAbsolutePosition = [self computeNewAbsolutePosition:superAbsolutePosition];
    
    _cssNode->layout.dimensions[CSS_WIDTH] = CSS_UNDEFINED;
    _cssNode->layout.dimensions[CSS_HEIGHT] = CSS_UNDEFINED;
    _cssNode->layout.position[CSS_LEFT] = 0;
    _cssNode->layout.position[CSS_TOP] = 0;

    [self _frameDidCalculated:isFrameChanged];
    NSArray * subcomponents = [_subcomponents copy];
    for (WXComponent *subcomponent in subcomponents) {
        [subcomponent _calculateFrameWithSuperAbsolutePosition:newAbsolutePosition gatherDirtyComponents:dirtyComponents];
    }
#else
    _isLayoutDirty = NO;
    CGRect newFrame = CGRectMake(WXRoundPixelValue(_flexCssNode->getLayoutPositionLeft()),
                                 WXRoundPixelValue(_flexCssNode->getLayoutPositionTop()),
                                 WXRoundPixelValue(_flexCssNode->getLayoutWidth()),
                                 WXRoundPixelValue(_flexCssNode->getLayoutHeight()));
    
    //TODO: test code,need remove
    if([self isKindOfClass:NSClassFromString(@"WXTextComponent")]){
        if(_flexCssNode->getLayoutPositionLeft()==0){
         
        }
        NSLog(@"~~~~~~text->%@, Left->%.f,Top->%.f,super->%@",[self valueForKey:@"_text"],_flexCssNode->getLayoutPositionLeft(),_flexCssNode->getLayoutPositionTop(),[self supercomponent]);
    }
    BOOL isFrameChanged = NO;
    if (!CGRectEqualToRect(newFrame, _calculatedFrame)) {
        isFrameChanged = YES;
        _calculatedFrame = newFrame;
        [dirtyComponents addObject:self];
    }
    
    CGPoint newAbsolutePosition = [self computeNewAbsolutePosition:superAbsolutePosition];
    
//    _flexCssNode->resetLayoutSize();
    
    [self _frameDidCalculated:isFrameChanged];
    NSArray * subcomponents = [_subcomponents copy];
    for (WXComponent *subcomponent in subcomponents) {
        [subcomponent _calculateFrameWithSuperAbsolutePosition:newAbsolutePosition gatherDirtyComponents:dirtyComponents];
    }
#endif
}

- (CGPoint)computeNewAbsolutePosition:(CGPoint)superAbsolutePosition
{
    // Not need absolutePosition any more
    return superAbsolutePosition;
}

- (void)_layoutDidFinish
{
    WXAssertMainThread();
    
    if (_positionType == WXPositionTypeSticky) {
        [self.ancestorScroller adjustSticky];
    }
    [self layoutDidFinish];
}

#ifndef USE_FLEX

#define WX_STYLE_FILL_CSS_NODE(key, cssProp, type)\
do {\
    id value = styles[@#key];\
    if (value) {\
        typeof(_cssNode->style.cssProp) convertedValue = (typeof(_cssNode->style.cssProp))[WXConvert type:value];\
        _cssNode->style.cssProp = convertedValue;\
        [self setNeedsLayout];\
    }\
} while(0);

#define WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp)\
do {\
    id value = styles[@#key];\
    if (value) {\
        CGFloat pixel = [self WXPixelType:value];\
        if (isnan(pixel)) {\
            WXLogError(@"Invalid NaN value for style:%@, ref:%@", @#key, self.ref);\
        } else {\
            _cssNode->style.cssProp = pixel;\
            [self setNeedsLayout];\
        }\
    }\
} while(0);

#define WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(key, cssProp)\
do {\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_TOP])\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_LEFT])\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_RIGHT])\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_BOTTOM])\
} while(0);

#else
#endif

- (CGFloat)WXPixelType:(id)value
{
    return [WXConvert WXPixelType:value scaleFactor:self.weexInstance.pixelScaleFactor];
}

- (void)_fillCSSNode:(NSDictionary *)styles
{
#ifndef USE_FLEX
    // flex
    WX_STYLE_FILL_CSS_NODE(flex, flex, CGFloat)
    WX_STYLE_FILL_CSS_NODE(flexDirection, flex_direction, css_flex_direction_t)
    WX_STYLE_FILL_CSS_NODE(alignItems, align_items, css_align_t)
    WX_STYLE_FILL_CSS_NODE(alignSelf, align_self, css_align_t)
    WX_STYLE_FILL_CSS_NODE(flexWrap, flex_wrap, css_wrap_type_t)
    WX_STYLE_FILL_CSS_NODE(justifyContent, justify_content, css_justify_t)
    
    // position
    WX_STYLE_FILL_CSS_NODE(position, position_type, css_position_type_t)
    WX_STYLE_FILL_CSS_NODE_PIXEL(top, position[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(left, position[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(right, position[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(bottom, position[CSS_BOTTOM])
    
    // dimension
    WX_STYLE_FILL_CSS_NODE_PIXEL(width, dimensions[CSS_WIDTH])
    WX_STYLE_FILL_CSS_NODE_PIXEL(height, dimensions[CSS_HEIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(minWidth, minDimensions[CSS_WIDTH])
    WX_STYLE_FILL_CSS_NODE_PIXEL(minHeight, minDimensions[CSS_HEIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(maxWidth, maxDimensions[CSS_WIDTH])
    WX_STYLE_FILL_CSS_NODE_PIXEL(maxHeight, maxDimensions[CSS_HEIGHT])
    
    // margin
    WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(margin, margin)
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginTop, margin[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginLeft, margin[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginRight, margin[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginBottom, margin[CSS_BOTTOM])
    
    // border
    WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(borderWidth, border)
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderTopWidth, border[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderLeftWidth, border[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderRightWidth, border[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderBottomWidth, border[CSS_BOTTOM])
    
    // padding
    WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(padding, padding)
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingTop, padding[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingLeft, padding[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingRight, padding[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingBottom, padding[CSS_BOTTOM])
#else
    // flex
    if (styles[@"flex"]) {
        _flexCssNode->setFlex([WXConvert CGFloat:styles[@"flex"]]);
    } else {
        // to make the default flex value is zero, yoga is nan, maybe this can configured by yoga config
        _flexCssNode->setFlex(0);
    }
    if (styles[@"flexDirection"]) {
        _flexCssNode->setFlexDirection([self fxFlexDirection:styles[@"flexDirection"]]);
    }
    if (styles[@"alignItems"]) {
        _flexCssNode->setAlignItems([self fxAlign:styles[@"alignItems"]]);
    }
    if (styles[@"alignSelf"]) {
        _flexCssNode->setAlignSelf([self fxAlignSelf:styles[@"alignSelf"]]);
    }
    if (styles[@"flexWrap"]) {
        _flexCssNode->setFlexWrap([self fxWrap:styles[@"flexWrap"]]);
    }
    if (styles[@"justifyContent"]) {
        _flexCssNode->setJustifyContent([self fxJustify:styles[@"justifyContent"]]);
    }
    
    // position
    if (styles[@"position"]) {
        _flexCssNode->setStylePositionType([self fxPositionType:styles[@"position"]]);
    }
    if (styles[@"top"]) {
        _flexCssNode->setStylePosition(WXCoreFlexLayout::WXCore_PositionEdge_Top, [WXConvert WXPixelType:styles[@"top"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"left"]) {
        _flexCssNode->setStylePosition(WXCoreFlexLayout::WXCore_PositionEdge_Left, [WXConvert WXPixelType:styles[@"left"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if(styles[@"right"]) {
        _flexCssNode->setStylePosition(WXCoreFlexLayout::WXCore_PositionEdge_Right, [WXConvert WXPixelType:styles[@"right"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"bottom"]) {
        _flexCssNode->setStylePosition(WXCoreFlexLayout::WXCore_PositionEdge_Bottom, [WXConvert WXPixelType:styles[@"bottom"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // dimension
    if (styles[@"width"]) {
        _flexCssNode->setStyleWidth([WXConvert WXPixelType:styles[@"width"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"height"]) {
        _flexCssNode->setStyleHeight([WXConvert WXPixelType:styles[@"height"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"minWidth"]) {
        _flexCssNode->setMinWidth([WXConvert WXPixelType:styles[@"minWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"minHeight"]) {
        _flexCssNode->setMinHeight([WXConvert WXPixelType:styles[@"minHeight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"maxWidth"]) {
        _flexCssNode->setMaxWidth([WXConvert WXPixelType:styles[@"maxWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"maxHeight"]) {
        _flexCssNode->setMaxHeight([WXConvert WXPixelType:styles[@"maxHeight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // margin
    if (styles[@"margin"]) {
        _flexCssNode->setMargin(WXCoreFlexLayout::WXCore_Margin_ALL, [WXConvert WXPixelType:styles[@"margin"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginTop"]) {
        _flexCssNode->setMargin(WXCoreFlexLayout::WXCore_Margin_Top, [WXConvert WXPixelType:styles[@"marginTop"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginBottom"]) {
        _flexCssNode->setMargin(WXCoreFlexLayout::WXCore_Margin_Bottom, [WXConvert WXPixelType:styles[@"marginBottom"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginRight"]) {
        _flexCssNode->setMargin(WXCoreFlexLayout::WXCore_Margin_Right, [WXConvert WXPixelType:styles[@"marginRight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginLeft"]) {
        _flexCssNode->setMargin(WXCoreFlexLayout::WXCore_Margin_Left, [WXConvert WXPixelType:styles[@"marginLeft"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // border
    if (styles[@"border"]) {
        _flexCssNode->setBorderWidth(WXCoreFlexLayout::WXCore_Border_Width_ALL, [WXConvert WXPixelType:styles[@"border"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"borderTopWidth"]) {
        _flexCssNode->setBorderWidth(WXCoreFlexLayout::WXCore_Border_Width_Top, [WXConvert WXPixelType:styles[@"borderTopWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    if (styles[@"borderLeftWidth"]) {
        _flexCssNode->setBorderWidth(WXCoreFlexLayout::WXCore_Border_Width_Left, [WXConvert WXPixelType:styles[@"borderLeftWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    if (styles[@"borderBottomWidth"]) {
        _flexCssNode->setBorderWidth(WXCoreFlexLayout::WXCore_Border_Width_Bottom, [WXConvert WXPixelType:styles[@"borderBottomWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"borderRightWidth"]) {
        _flexCssNode->setBorderWidth(WXCoreFlexLayout::WXCore_Border_Width_Right, [WXConvert WXPixelType:styles[@"borderRightWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // padding
    if (styles[@"padding"]) {
        _flexCssNode->setPadding(WXCoreFlexLayout::WXCore_Padding_ALL, [WXConvert WXPixelType:styles[@"padding"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingTop"]) {
        _flexCssNode->setPadding(WXCoreFlexLayout::WXCore_Padding_Top, [WXConvert WXPixelType:styles[@"paddingTop"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingLeft"]) {
        _flexCssNode->setPadding(WXCoreFlexLayout::WXCore_Padding_Left, [WXConvert WXPixelType:styles[@"paddingLeft"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingBottom"]) {
        _flexCssNode->setPadding(WXCoreFlexLayout::WXCore_Padding_Bottom, [WXConvert WXPixelType:styles[@"paddingBottom"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingRight"]) {
        _flexCssNode->setPadding(WXCoreFlexLayout::WXCore_Padding_Right, [WXConvert WXPixelType:styles[@"paddingRight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    [self setNeedsLayout];
#endif
}

#ifndef USE_FLEX

#define WX_STYLE_RESET_CSS_NODE(key, cssProp, defaultValue)\
do {\
    if (styles && [styles containsObject:@#key]) {\
        _cssNode->style.cssProp = defaultValue;\
        [self setNeedsLayout];\
    }\
} while(0);

#define WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(key, cssProp, defaultValue)\
do {\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_TOP], defaultValue)\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_LEFT], defaultValue)\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_RIGHT], defaultValue)\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_BOTTOM], defaultValue)\
} while(0);

#else
#endif


- (void)_resetCSSNode:(NSArray *)styles;
{
#ifndef USE_FLEX
    // flex
    WX_STYLE_RESET_CSS_NODE(flex, flex, 0.0)
    WX_STYLE_RESET_CSS_NODE(flexDirection, flex_direction, CSS_FLEX_DIRECTION_COLUMN)
    WX_STYLE_RESET_CSS_NODE(alignItems, align_items, CSS_ALIGN_STRETCH)
    WX_STYLE_RESET_CSS_NODE(alignSelf, align_self, CSS_ALIGN_AUTO)
    WX_STYLE_RESET_CSS_NODE(flexWrap, flex_wrap, CSS_NOWRAP)
    WX_STYLE_RESET_CSS_NODE(justifyContent, justify_content, CSS_JUSTIFY_FLEX_START)

    // position
    WX_STYLE_RESET_CSS_NODE(position, position_type, CSS_POSITION_RELATIVE)
    WX_STYLE_RESET_CSS_NODE(top, position[CSS_TOP], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(left, position[CSS_LEFT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(right, position[CSS_RIGHT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(bottom, position[CSS_BOTTOM], CSS_UNDEFINED)
    
    // dimension
    WX_STYLE_RESET_CSS_NODE(width, dimensions[CSS_WIDTH], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(height, dimensions[CSS_HEIGHT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(minWidth, minDimensions[CSS_WIDTH], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(minHeight, minDimensions[CSS_HEIGHT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(maxWidth, maxDimensions[CSS_WIDTH], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(maxHeight, maxDimensions[CSS_HEIGHT], CSS_UNDEFINED)
    
    // margin
    WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(margin, margin, 0.0)
    WX_STYLE_RESET_CSS_NODE(marginTop, margin[CSS_TOP], 0.0)
    WX_STYLE_RESET_CSS_NODE(marginLeft, margin[CSS_LEFT], 0.0)
    WX_STYLE_RESET_CSS_NODE(marginRight, margin[CSS_RIGHT], 0.0)
    WX_STYLE_RESET_CSS_NODE(marginBottom, margin[CSS_BOTTOM], 0.0)
    
    // border
    WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(borderWidth, border, 0.0)
    WX_STYLE_RESET_CSS_NODE(borderTopWidth, border[CSS_TOP], 0.0)
    WX_STYLE_RESET_CSS_NODE(borderLeftWidth, border[CSS_LEFT], 0.0)
    WX_STYLE_RESET_CSS_NODE(borderRightWidth, border[CSS_RIGHT], 0.0)
    WX_STYLE_RESET_CSS_NODE(borderBottomWidth, border[CSS_BOTTOM], 0.0)
    
    // padding
    WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(padding, padding, 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingTop, padding[CSS_TOP], 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingLeft, padding[CSS_LEFT], 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingRight, padding[CSS_RIGHT], 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingBottom, padding[CSS_BOTTOM], 0.0)
#else
#endif
}

#pragma mark CSS Node Override

#ifndef USE_FLEX
#if defined __cplusplus
extern "C" {
#endif
static void cssNodePrint(void *context)
{
    WXComponent *component = (__bridge WXComponent *)context;
    // TODO:
    printf("%s:%s ", component.ref.UTF8String, component->_type.UTF8String);
}

static css_node_t * cssNodeGetChild(void *context, int i)
{
    WXComponent *component = (__bridge WXComponent *)context;
    NSArray *subcomponents = component->_subcomponents;
    for (int j = 0; j <= i && j < subcomponents.count; j++) {
        WXComponent *child = subcomponents[j];
        if (!child->_isNeedJoinLayoutSystem) {
            i++;
        }
    }
    
    if(i >= 0 && i < subcomponents.count){
        WXComponent *child = subcomponents[i];
//        WXLogInfo(@"FlexLayout -- P:%@ -> C:%@",component,(__bridge WXComponent *)child->_cssNode->context);
        return child->_cssNode;
    }
    
    WXAssert(NO, @"Can not find component:%@'s css node child at index: %ld, totalCount:%ld", component, i, subcomponents.count);
    return NULL;
}

static bool cssNodeIsDirty(void *context)
{
    WXAssertComponentThread();
    
    WXComponent *component = (__bridge WXComponent *)context;
    BOOL needsLayout = [component needsLayout];
    
    return needsLayout;
}
    
static css_dim_t cssNodeMeasure(void *context, float width, css_measure_mode_t widthMode, float height, css_measure_mode_t heightMode)
{
    WXComponent *component = (__bridge WXComponent *)context;
    CGSize (^measureBlock)(CGSize) = [component measureBlock];
    
    if (!measureBlock) {
        return (css_dim_t){NAN, NAN};
    }
    
    CGSize constrainedSize = CGSizeMake(width, height);
    CGSize resultSize = measureBlock(constrainedSize);
    return (css_dim_t){(float)resultSize.width, (float)resultSize.height};
}
#if defined __cplusplus
};
#endif

#else

static WXCoreFlexLayout::WXCoreSize flexCssNodeMeasure(WXCoreFlexLayout::WXCoreLayoutNode *node, float width, float height){
    WXComponent *component = (__bridge WXComponent *)(node->getContext());
    NSLog(@"~~~~~~ text->%@, flexCssNodeMeasure start",[component valueForKey:@"_text"]);
    CGSize (^measureBlock)(CGSize) = [component measureBlock];
    
    if (!measureBlock) {
        return (WXCoreFlexLayout::WXCoreSize){NAN, NAN};
    }
    CGSize constrainedSize = CGSizeMake(width, height);
    CGSize resultSize = measureBlock(constrainedSize);
    WXCoreFlexLayout::WXCoreSize size;
    size.height=(float)resultSize.height;
    size.width=(float)resultSize.width;
    NSLog(@"~~~~~~ text->%@ flexCssNodeMeasure end:%.f,%.f",[component valueForKey:@"_text"],size.width,size.height);
//    WXLogInfo(@"FlexLayout -- measure:[%@,width:%f,height:%f]",node->getContext(),size.width,size.height);
    return size;
}

-(WXCoreFlexLayout::WXCorePositionType)fxPositionType:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"absolute"]) {
            return WXCoreFlexLayout::WXCore_PositionType_Absolute;
        } else if ([value isEqualToString:@"relative"]) {
            return WXCoreFlexLayout::WXCore_PositionType_Relative;
        } else if ([value isEqualToString:@"fixed"]) {
            return WXCoreFlexLayout::WXCore_PositionType_Fixed;
        } else if ([value isEqualToString:@"sticky"]) {
            return WXCoreFlexLayout::WXCore_PositionType_Relative;
        }
    }
    return WXCoreFlexLayout::WXCore_PositionType_Relative;
}

- (WXCoreFlexLayout::WXCoreFlexDirection)fxFlexDirection:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"column"]) {
            return WXCoreFlexLayout::WXCore_Flex_Direction_Column;
        } else if ([value isEqualToString:@"column-reverse"]) {
            return WXCoreFlexLayout::WXCore_Flex_Direction_Column_Reverse;
        } else if ([value isEqualToString:@"row"]) {
            return WXCoreFlexLayout::WXCore_Flex_Direction_Row;
        } else if ([value isEqualToString:@"row-reverse"]) {
            return WXCoreFlexLayout::WXCore_Flex_Direction_Row_Reverse;
        }
    }
    return WXCoreFlexLayout::WXCore_Flex_Direction_Column;
}

//TODO
- (WXCoreFlexLayout::WXCoreAlignItems)fxAlign:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"stretch"]) {
            return WXCoreFlexLayout::WXCore_AlignItems_Stretch;
        } else if ([value isEqualToString:@"flex-start"]) {
            return WXCoreFlexLayout::WXCore_AlignItems_Flex_Start;
        } else if ([value isEqualToString:@"flex-end"]) {
            return WXCoreFlexLayout::WXCore_AlignItems_Flex_End;
        } else if ([value isEqualToString:@"center"]) {
            return WXCoreFlexLayout::WXCore_AlignItems_Center;
        } else if ([value isEqualToString:@"auto"]) {
//            return YGAlignAuto;
        } else if ([value isEqualToString:@"baseline"]) {
//            return YGAlignBaseline;
        }
    }
    
    return WXCoreFlexLayout::WXCore_AlignItems_Stretch;
}

- (WXCoreFlexLayout::WXCoreAlignSelf)fxAlignSelf:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"stretch"]) {
            return WXCoreFlexLayout::WXCore_AlignSelf_Stretch;
        } else if ([value isEqualToString:@"flex-start"]) {
            return WXCoreFlexLayout::WXCore_AlignSelf_Flex_Start;
        } else if ([value isEqualToString:@"flex-end"]) {
            return WXCoreFlexLayout::WXCore_AlignSelf_Flex_End;
        } else if ([value isEqualToString:@"center"]) {
            return WXCoreFlexLayout::WXCore_AlignSelf_Center;
        } else if ([value isEqualToString:@"auto"]) {
            return WXCoreFlexLayout::WXCore_AlignSelf_Auto;
        } else if ([value isEqualToString:@"baseline"]) {
            //            return YGAlignBaseline;
        }
    }
    
    return WXCoreFlexLayout::WXCore_AlignSelf_Stretch;
}

- (WXCoreFlexLayout::WXCoreFlexWrap)fxWrap:(id)value
{
    if([value isKindOfClass:[NSString class]]) {
        if ([value isEqualToString:@"nowrap"]) {
            return WXCoreFlexLayout::WXCore_Wrap_NoWrap;
        } else if ([value isEqualToString:@"wrap"]) {
            return WXCoreFlexLayout::WXCore_Wrap_Wrap;
        } else if ([value isEqualToString:@"wrap-reverse"]) {
            return WXCoreFlexLayout::WXCore_Wrap_WrapReverse;
        }
    }
    
    return WXCoreFlexLayout::WXCore_Wrap_NoWrap;
}

- (WXCoreFlexLayout::WXCoreJustifyContent)fxJustify:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"flex-start"]) {
            return WXCoreFlexLayout::WXCore_Justify_Flex_Start;
        } else if ([value isEqualToString:@"center"]) {
            return WXCoreFlexLayout::WXCore_Justify_Center;
        } else if ([value isEqualToString:@"flex-end"]) {
            return WXCoreFlexLayout::WXCore_Justify_Flex_End;
        } else if ([value isEqualToString:@"space-between"]) {
            return WXCoreFlexLayout::WXCore_Justify_Space_Between;
        } else if ([value isEqualToString:@"space-around"]) {
            return WXCoreFlexLayout::WXCore_Justify_Space_Around;
        }
    }
    
    return WXCoreFlexLayout::WXCore_Justify_Flex_Start;
}


- (void)_insertChildCssNode:(WXComponent*)subcomponent atIndex:(NSInteger)index
{
    self.flexCssNode->addChildAt(subcomponent.flexCssNode, (uint32_t)index);
    NSLog(@"~~~~~ -- P:%@ -> C:%@",self,subcomponent);
//    WXLogInfo(@"FlexLayout -- P:%@ -> C:%@",self,subcomponent);
}

#endif

@end
