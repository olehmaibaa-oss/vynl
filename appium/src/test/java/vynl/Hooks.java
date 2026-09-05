package vynl;

import io.appium.java_client.ios.IOSDriver;
import io.cucumber.java.After;
import io.cucumber.java.Before;
import org.openqa.selenium.remote.DesiredCapabilities;

import java.net.URL;
import java.time.Duration;

public class Hooks {

    public static IOSDriver driver;

    @Before
    public void setUp() throws Exception {
        DesiredCapabilities caps = new DesiredCapabilities();
        caps.setCapability("appium:wdaLaunchTimeout", 240000);
        caps.setCapability("appium:wdaConnectionTimeout", 240000);
        caps.setCapability("appium:usePrebuiltWDA", false);
        caps.setCapability("appium:useNewWDA", true);
        caps.setCapability("platformName", "iOS");
        caps.setCapability("appium:automationName", "XCUITest");
        caps.setCapability("appium:deviceName", "iPhone 17 Pro Max");
        caps.setCapability("appium:platformVersion", "26.5");
        caps.setCapability("appium:udid", "A0EC2CC4-88A7-423A-B851-C59705474E84");
        caps.setCapability("appium:bundleId", "dev.vynl");
        caps.setCapability("appium:processArguments",
                java.util.Map.of("args", java.util.List.of("-uitesting")));


        driver = new IOSDriver(new URL("http://127.0.0.1:4723"), caps);
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
    }

    @After
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}