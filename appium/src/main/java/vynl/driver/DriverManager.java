package vynl.driver;

import io.appium.java_client.ios.IOSDriver;

/**
 * Holds the driver for the current thread so page objects and steps can reach it
 * without a public static field. ThreadLocal now, so parallel execution later
 * doesn't require touching every page object.
 */
public final class DriverManager {

    private static final ThreadLocal<IOSDriver> DRIVER = new ThreadLocal<>();

    private DriverManager() {
    }

    public static void set(IOSDriver driver) {
        DRIVER.set(driver);
    }

    public static IOSDriver get() {
        IOSDriver driver = DRIVER.get();
        if (driver == null) {
            throw new IllegalStateException("Driver is not initialised — check Hooks @Before");
        }
        return driver;
    }

    public static void quit() {
        IOSDriver driver = DRIVER.get();
        if (driver != null) {
            driver.quit();
            DRIVER.remove();
        }
    }
}
