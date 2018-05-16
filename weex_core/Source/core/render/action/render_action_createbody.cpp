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
#include "render_action_createbody.h"

namespace WeexCore {

  RenderActionCreateBody::RenderActionCreateBody(const std::string &pageId, const RenderObject *render) {
    this->mAttributes = render->Attributes();
    this->mStyles = render->Styles();
    this->mEvents = render->Events();
    this->mMargins = render->GetMargins();
    this->mPaddings = render->GetPaddings();
    this->mBorders = render->GetBorders();
    this->mPageId = pageId;
    this->mComponentType = render->Type();
    this->mRef = render->Ref();
  }

  void RenderActionCreateBody::ExecuteAction() {
    RenderPage *page = RenderManager::GetInstance()->GetPage(mPageId);
    if (page == nullptr)
      return;

    long long startTime = getCurrentTime();
#ifdef __ANDROID__
    Bridge_Impl_Android::getInstance()->callCreateBody(mPageId.c_str(), mComponentType.c_str(), mRef.c_str(),
                                                       mStyles, mAttributes, mEvents,
                                                       mMargins, mPaddings, mBorders);
#endif
    page->JniCallTime(getCurrentTime() - startTime);
    page->AddElementActionJNITime(getCurrentTime() - startTime);
  }
}
