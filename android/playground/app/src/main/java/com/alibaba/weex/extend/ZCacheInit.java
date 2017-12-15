package com.alibaba.weex.extend;

import android.app.Application;

import com.taobao.weex.utils.WXLogUtils;
import com.taobao.zcache.ZCache;
import com.taobao.zcache.utils.ILog;
import com.taobao.zcache.utils.ZLog;

/**
 * Created by moxun on 12/12/2017.
 */

public class ZCacheInit {
  public static void initZCache(Application application, String appKey, String appVersion) {
    ZLog.setLogImpl(new ILog() {
      @Override
      public void d(String tag, String msg) {
        WXLogUtils.d(tag, msg);
      }

      @Override
      public void d(String tag, String msg, Throwable tr) {
        WXLogUtils.d(tag + msg, tr);
      }

      @Override
      public void e(String tag, String msg) {
        WXLogUtils.e(tag, msg);
      }

      @Override
      public void e(String tag, String msg, Throwable tr) {
        WXLogUtils.e(tag + msg, tr);
      }

      @Override
      public void i(String tag, String msg) {
        WXLogUtils.i(tag, msg);
      }

      @Override
      public void i(String tag, String msg, Throwable tr) {
        WXLogUtils.i(tag + msg, tr);
      }

      @Override
      public void v(String tag, String msg) {
        WXLogUtils.v(tag, msg);
      }

      @Override
      public void v(String tag, String msg, Throwable tr) {
        WXLogUtils.v(tag + msg, tr);
      }

      @Override
      public void w(String tag, String msg) {
        WXLogUtils.w(tag, msg);
      }

      @Override
      public void w(String tag, String msg, Throwable tr) {
        WXLogUtils.w(tag + msg, tr);
      }

      @Override
      public boolean isLogLevelEnabled(int level) {
        return true;
      }
    });
    ZCache.initZCache(application, appKey, appVersion);
  }
}
