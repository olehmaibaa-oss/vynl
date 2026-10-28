package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.remote.RemoteWebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import vynl.config.Config;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Shared plumbing for page objects: holds the driver and wraps the few
 * interactions every screen needs.
 *
 * <p>Every lookup here waits explicitly. There is deliberately no implicit
 * wait configured on the driver: mixing the two makes timings unpredictable,
 * because the implicit wait applies inside each polling attempt of the
 * explicit one.
 */
public abstract class BasePage {

    protected final IOSDriver driver;
    private final WebDriverWait wait;

    protected BasePage(IOSDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Config.elementTimeout());
    }

    /** Waits for the element to exist in the hierarchy. */
    protected WebElement find(String accessibilityId) {
        return waitFor(ExpectedConditions.presenceOfElementLocated(byId(accessibilityId)));
    }

    /** Waits for the element to be rendered and non-zero sized. */
    protected WebElement findVisible(String accessibilityId) {
        return waitFor(ExpectedConditions.visibilityOfElementLocated(byId(accessibilityId)));
    }

    /** Waits for the element to be visible and enabled, then taps it. */
    protected void tap(String accessibilityId) {
        waitFor(ExpectedConditions.elementToBeClickable(byId(accessibilityId))).click();
    }

    /**
     * Taps an element that may be scrolled out of view — e.g. a row below the
     * keyboard in a long form. Plain {@link #tap} waits for "clickable", which
     * includes displayed, and an off-screen row never is. XCUITest's own tap
     * scrolls the element to hittable first, so waiting for presence is enough.
     * ({@code mobile: scroll toVisible} was tried and can't find the scrollable
     * parent inside a SwiftUI Form.)
     */
    protected void scrollToAndTap(String accessibilityId) {
        find(accessibilityId).click();
    }

    protected void type(String accessibilityId, String text) {
        findVisible(accessibilityId).sendKeys(text);
    }

    /**
     * Replaces a field's content. Edit forms open pre-filled, so a plain
     * {@link #type} would append to what is already there.
     */
    protected void clearAndType(String accessibilityId, String text) {
        WebElement field = findVisible(accessibilityId);
        field.clear();
        field.sendKeys(text);
    }

    /**
     * The field's current text. Note that XCUITest reports an empty text field's
     * placeholder as its value, so callers comparing against "" will be misled.
     */
    protected String valueOf(String accessibilityId) {
        return find(accessibilityId).getAttribute("value");
    }

    protected boolean isEnabled(String accessibilityId) {
        return find(accessibilityId).isEnabled();
    }

    /**
     * Enabled state of a toolbar button. On iOS 26 a SwiftUI toolbar button is
     * wrapped in an {@code XCUIElementTypeOther} that carries the same
     * identifier and always reports {@code enabled=true}; a plain lookup by
     * accessibility id returns that wrapper first. The button inside reports its
     * state truthfully, so target the Button element itself.
     */
    protected boolean isButtonEnabled(String accessibilityId) {
        return waitFor(ExpectedConditions.presenceOfElementLocated(button(accessibilityId))).isEnabled();
    }

    protected static By button(String accessibilityId) {
        return AppiumBy.iOSNsPredicateString(
                "type == 'XCUIElementTypeButton' AND name == '" + accessibilityId + "'");
    }

    /**
     * Swipes a list row left to reveal its delete action, then taps it. A swipe
     * plus an explicit tap rather than a full-width swipe: the full swipe also
     * deletes, but only past a distance threshold, so it's the flakier path. The
     * revealed "Delete" is a system swipe action and carries no identifier of
     * ours, hence the label match.
     */
    protected void swipeToDelete(By row) {
        WebElement element = waitFor(ExpectedConditions.visibilityOfElementLocated(row));
        driver.executeScript("mobile: swipe", Map.of(
                "direction", "left",
                "elementId", ((RemoteWebElement) element).getId()));
        waitFor(ExpectedConditions.elementToBeClickable(SWIPE_DELETE_ACTION)).click();
    }

    /**
     * Scrolls until the element exists in the hierarchy and returns it. SwiftUI
     * Lists and Forms build rows lazily: a row a few screens down is not in the
     * page source at all until it has been scrolled near (E2-S5's 30 moods made
     * this the normal case). Looks down first, then back up. Presence, not
     * visibility: a row under the keyboard is present, and XCUITest's click
     * scrolls it to hittable itself.
     */
    protected WebElement scrollTo(By locator, String listId) {
        for (String direction : new String[]{"down", "up"}) {
            for (int i = 0; i < 12; i++) {
                List<WebElement> found = driver.findElements(locator);
                if (!found.isEmpty()) return found.get(0);
                scrollList(listId, direction);
            }
        }
        throw new org.openqa.selenium.NoSuchElementException("Not found after scrolling " + listId + ": " + locator);
    }

    /**
     * Moves the list with this identifier about a third of its height in
     * {@code direction} ("down" = towards later rows).
     *
     * <p>Always by id: with a sheet up, the screen behind it and the keyboard's
     * suggestion bar are scroll views too. And a drag, not {@code mobile: scroll}
     * or {@code mobile: swipe}: in a SwiftUI Form {@code mobile: scroll} does
     * nothing (7 s per no-op), and a swipe flings past rows, so a lazily built
     * row in the middle is never in the tree when we look. The drag stays in the
     * upper half, clear of the keyboard.
     */
    protected void scrollList(String listId, String direction) {
        org.openqa.selenium.Rectangle r = find(listId).getRect();
        int x = r.getX() + r.getWidth() / 2;
        int low = r.getY() + (int) (r.getHeight() * 0.55);
        int high = r.getY() + (int) (r.getHeight() * 0.2);
        boolean down = direction.equals("down");
        driver.executeScript("mobile: dragFromToForDuration", Map.of(
                "duration", 0.1,
                "fromX", x, "fromY", down ? low : high,
                "toX", x, "toY", down ? high : low));
    }

    private static final By SWIPE_DELETE_ACTION = AppiumBy.iOSNsPredicateString(
            "type == 'XCUIElementTypeButton' AND label == 'Delete'");

    /** Labels of every element with this identifier, in on-screen order. */
    protected List<String> labelsOf(String accessibilityId) {
        find(accessibilityId);
        return driver.findElements(byId(accessibilityId)).stream()
                .map(e -> e.getAttribute("label"))
                .toList();
    }

    protected boolean isVisible(String accessibilityId) {
        return isVisible(byId(accessibilityId), Config.elementTimeout());
    }

    /**
     * Visibility check with an explicit budget. Pass {@link Config#absenceTimeout()}
     * when the expected answer is "no" — a negative check paid at the full
     * element timeout makes a suite crawl.
     */
    protected boolean isVisible(By locator, Duration timeout) {
        try {
            new WebDriverWait(driver, timeout)
                    .until(ExpectedConditions.visibilityOfElementLocated(locator));
            return true;
        } catch (TimeoutException e) {
            return false;
        }
    }

    /**
     * Visibility check scoped to a container, for screens where the same string
     * can appear both inside and outside the content area (the release detail
     * screen renders the title in the navigation bar as well as in the body).
     */
    protected boolean isVisibleWithin(By container, By locator, Duration timeout) {
        try {
            new WebDriverWait(driver, timeout)
                    .until(ExpectedConditions.visibilityOfNestedElementsLocatedBy(container, locator));
            return true;
        } catch (TimeoutException e) {
            return false;
        }
    }

    /** Waits for the element to disappear (or never appear). */
    protected boolean isGone(By locator, Duration timeout) {
        try {
            return new WebDriverWait(driver, timeout)
                    .until(ExpectedConditions.invisibilityOfElementLocated(locator));
        } catch (TimeoutException e) {
            return false;
        }
    }

    protected <T> T waitFor(java.util.function.Function<org.openqa.selenium.WebDriver, T> condition) {
        return wait.until(condition);
    }

    protected static By byId(String accessibilityId) {
        return AppiumBy.accessibilityId(accessibilityId);
    }

    /**
     * Matches a StaticText by its exact accessibility label. Values on screens
     * without per-field identifiers are asserted through this — kept here so
     * the predicate lives in one place instead of once per page object.
     *
     * <p>Note what a label actually is: a plain SwiftUI text exposes its own
     * string ("Surgeon"), but a {@code LabeledContent} exposes the pair joined
     * with a comma ("Artist, Surgeon"). Callers must pass what the element
     * really carries; see {@code ReleaseDetailPage.fieldLabel}.
     */
    protected static By staticTextWithLabel(String label) {
        return AppiumBy.iOSNsPredicateString(
                "type == 'XCUIElementTypeStaticText' AND label == '" + label + "'");
    }
}
