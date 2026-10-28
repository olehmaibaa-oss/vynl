package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.support.ui.ExpectedConditions;
import vynl.config.Config;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Set;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The mood vocabulary, pushed from the gear on the Collection screen. Since
 * E2-S5 it is grouped: a {@code moods.group} header (label = group name) above
 * that group's {@code moods.row} buttons (label = mood name), A–Z.
 *
 * <p>30 moods don't fit one screen and the List builds rows lazily, so reads go
 * through {@link #readAll()}, which scrolls top to bottom and stitches the
 * screens together; single-row actions scroll to their row first.
 */
public class MoodVocabularyPage extends BasePage {

    private static final String ROW = "moods.row";
    private static final String LIST = "moods.list";
    private static final String GROUP = "moods.group";
    private static final String ADD_BUTTON = "moods.addButton";
    /** The first group's header: present only when the list is at (or near) the top. */
    private static final By FIRST_GROUP = AppiumBy.iOSNsPredicateString(
            "name == 'moods.group' AND label == 'Dark & Driving'");

    /** A header or a row as it appears in the page source, in tree order (= on-screen order). */
    private static final Pattern ENTRY = Pattern.compile(
            "<XCUIElementType\\w+ [^>]*?name=\"(moods\\.(?:group|row))\" label=\"([^\"]*)\"");

    public MoodVocabularyPage(IOSDriver driver) {
        super(driver);
    }

    public boolean isDisplayed() {
        return isVisible(button(ADD_BUTTON), Config.elementTimeout());
    }

    /**
     * Every group with its moods, in on-screen order. Scrolls to the top, then
     * reads one page source per screen and stitches them together, stopping when
     * a scroll shows nothing new. A page source of this screen is the expensive
     * call, so callers read once and query the result (see MoodSteps).
     */
    public Map<String, List<String>> readAll() {
        for (int i = 0; i < 15 && driver.findElements(FIRST_GROUP).isEmpty(); i++) {
            scrollList(LIST, "up");
        }
        Map<String, List<String>> groups = new LinkedHashMap<>();
        Set<String> seen = new HashSet<>();
        String current = null;
        for (int pass = 0; pass < 15; pass++) {
            boolean anythingNew = false;
            Matcher m = ENTRY.matcher(driver.getPageSource());
            while (m.find()) {
                String label = unescape(m.group(2));
                boolean header = m.group(1).equals(GROUP);
                if (header) current = label;
                if (!seen.add(m.group(1) + "|" + label)) continue;
                anythingNew = true;
                if (header) groups.put(label, new ArrayList<>());
                else if (current != null) groups.get(current).add(label);
            }
            if (!anythingNew) break;
            scrollList(LIST, "down");
        }
        return groups;
    }

    public boolean isListed(String mood) {
        try {
            scrollTo(row(mood), LIST);
            return true;
        } catch (org.openqa.selenium.NoSuchElementException e) {
            return false;
        }
    }

    public MoodFormPage tapAdd() {
        tap(ADD_BUTTON);
        return new MoodFormPage(driver);
    }

    /** Tapping a row opens the mood for renaming, pre-filled. */
    public MoodFormPage openMood(String mood) {
        scrollTo(row(mood), LIST).click();
        return new MoodFormPage(driver);
    }

    public MoodVocabularyPage swipeDelete(String mood) {
        scrollTo(row(mood), LIST);
        swipeToDelete(row(mood));
        return this;
    }

    /** Pops back to the collection through the navigation bar. */
    public CollectionPage goBack() {
        driver.navigate().back();
        return new CollectionPage(driver);
    }

    private static By row(String mood) {
        return AppiumBy.iOSNsPredicateString("name == '" + ROW + "' AND label == '" + mood + "'");
    }

    private static String unescape(String xml) {
        return xml.replace("&amp;", "&").replace("&quot;", "\"").replace("&apos;", "'")
                .replace("&lt;", "<").replace("&gt;", ">");
    }
}
