plugins {
    java
}

group = "dev.learnpaper"
version = "1.0.0"

dependencies {
    compileOnly("io.papermc.paper:paper-api:26.1.2.build.69-stable")
}

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(25))
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release.set(25)
}

tasks.processResources {
    val props = mapOf("version" to project.version)
    inputs.properties(props)
    filteringCharset = "UTF-8"
    filesMatching("plugin.yml") {
        expand(props)
    }
}

tasks.jar {
    archiveBaseName.set("LearnPaperHello")
}
