package vynl.pages;

import io.appium.java_client.ios.IOSDriver;

/** The Crates tab. A placeholder until E4. */
public class CratesPage extends BasePage {

    private static final String PLACEHOLDER = "crates.placeholder";

    public CratesPage(IOSDriver driver) {
        super(driver);
    }

    public boolean isPlaceholderVisible() {
        return isVisible(PLACEHOLDER);
    }
}
