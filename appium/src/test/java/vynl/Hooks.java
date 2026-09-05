package vynl;

import io.appium.java_client.ios.IOSDriver;
import io.cucumber.java.After;
import io.cucumber.java.Before;
import org.openqa.selenium.remote.DesiredCapabilities;

import java.util.List;
import java.util.Map;

public class Hooks {

    @Before
    public void setUp() {
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
        caps.setCapability("appium:processArguments", Map.of("args", List.of("-uitesting")));

        // No implicit wait on purpose — page objects wait explicitly, and mixing
        // the two makes timings unpredictable.
        DriverManager.set(new IOSDriver(Config.appiumUrl(), caps));
    }

    @After
    public void tearDown() {
        DriverManager.quit();
    }
}
