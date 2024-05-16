# local_notification_demo

## iOS Setting
- AppDelegate.m/AppDelegate.swift
```
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```
## Android Setting
### Gradle setup
- android/app/build.gradle
```
android {
  defaultConfig {
    multiDexEnabled true
  }

  compileOptions {
    // Flag to enable support for the new language APIs
    coreLibraryDesugaringEnabled true
    // Sets Java compatibility to Java 8
    sourceCompatibility JavaVersion.VERSION_1_8
    targetCompatibility JavaVersion.VERSION_1_8
  }
}

dependencies {
  coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:1.2.2'
}
```
- android/build.gradle
```
buildscript {
   ...

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.1'
        implementation 'androidx.window:window:1.0.0'
        implementation 'androidx.window:window-java:1.0.0'
        ...
    }
```
### AndroidManifest.xml setup
```
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
...
<activity
    android:showWhenLocked="true"
    android:turnScreenOn="true">
...
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```
## pubspec.yaml
```
dependencies:
  ...
  flutter_local_notifications: ^17.1.2
  flutter_timezone: ^1.0.4 // 지금은 seoul로 직접 설정했지만, 자동으로 local location을 설정하고 싶은 경우
```
- https://pub.dev/packages/flutter_local_notifications
