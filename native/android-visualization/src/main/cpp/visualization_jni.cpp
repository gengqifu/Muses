#include <jni.h>

extern "C" JNIEXPORT jstring JNICALL
Java_com_soundwave_visualization_core_NativeBridge_nativeVersion(JNIEnv* env,
                                                                 jobject /*thiz*/) {
  return env->NewStringUTF("0.0.2-native-stub");
}
