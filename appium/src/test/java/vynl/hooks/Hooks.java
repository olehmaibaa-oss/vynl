package vynl.hooks;

import io.appium.java_client.ios.IOSDriver;
import io.cucumber.java.After;
import io.cucumber.java.Before;
import io.cucumber.java.Scenario;
import org.openqa.selenium.remote.DesiredCapabilities;
import vynl.config.Config;
import vynl.driver.DriverManager;

import java.util.List;
import java.util.Map;

public class Hooks {

    @Before
    public void setUp(Scenario scenario) {
        DesiredCapabilities caps = new DesiredCapabilities();
        caps.setCapability("platformName", "iOS");
        caps.setCapability("appium:automationName", "XCUITest");
        caps.setCapability("appium:deviceName", Config.deviceName());
        caps.setCapability("appium:platformVersion", Config.platformVersion());
        caps.setCapability("appium:udid", Config.udid());
        caps.setCapability("appium:bundleId", Config.bundleId());
        caps.setCapability("appium:wdaLaunchTimeout", Config.wdaLaunchTimeoutMs());
        caps.setCapability("appium:wdaConnectionTimeout", Config.wdaConnectionTimeoutMs());
        caps.setCapability("appium:useNewWDA", Config.useNewWda());
        caps.setCapability("appium:usePrebuiltWDA", Config.usePrebuiltWda());

        // In-memory SwiftData store, so every run starts from a clean collection.
        // @no-camera scenarios: the app behaves as on a device without a camera
        // (the iOS 26 simulator reports one).
        List<String> args = scenario.getSourceTagNames().contains("@no-camera")
                ? List.of("-uitesting", "-uitesting-noCamera")
                : List.of("-uitesting");
        caps.setCapability("appium:processArguments", Map.of("args", args));

        // No implicit wait on purpose — page objects wait explicitly, and mixing
        // the two makes timings unpredictable.
        DriverManager.set(new IOSDriver(Config.appiumUrl(), caps));
    }

    @After
    public void tearDown() {
        DriverManager.quit();
    }
}
