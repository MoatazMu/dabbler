allprojects {
    afterEvaluate {
        if (this.hasProperty("android")) {
            val android = this.extensions.getByName("android")
            
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(36)
            }
        }
    }
}
