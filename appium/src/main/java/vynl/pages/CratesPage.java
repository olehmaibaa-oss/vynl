package vynl.pages;

import io.appium.java_client.ios.IOSDriver;
import vynl.config.Config;

/** The Crates tab. A placeholder until E4. */
public class CratesPage extends BasePage {

    private static final String PLACEHOLDER = "crates.placeholder";
    /** The add button exists only on Collection; Crates gets its own in E4. */
    private static final String ADD_BUTTON = "collection.toolbarAddButton";

    public CratesPage(IOSDriver driver) {
        super(driver);
    }

    public boolean isPlaceholderVisible() {
        return isVisible(PLACEHOLDER);
    }

    /**
     * DR-3: the section title is content (a header StaticText), not the
     * navigation bar title, which stays set but is not drawn.
     */
    public boolean showsTitle(String title) {
        return isVisible(staticTextWithLabel(title), Config.elementTimeout());
    }

    public boolean hasNoAddButton() {
        return isGone(byId(ADD_BUTTON), Config.absenceTimeout());
    }
}
