package vynl;

import io.appium.java_client.AppiumBy;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class AddReleaseSteps {

    @Given("the app is launched")
    public void theAppIsLaunched() {
        // драйвер уже піднятий у Hooks, апка запущена
    }

    @When("I add a release with artist {string}, title {string} and genre {string}")
    public void iAddRelease(String artist, String title, String genre) {
        Hooks.driver.findElement(AppiumBy.accessibilityId("collection.addReleaseButton")).click();
        Hooks.driver.findElement(AppiumBy.accessibilityId("addRelease.artistField")).sendKeys(artist);
        Hooks.driver.findElement(AppiumBy.accessibilityId("addRelease.titleField")).sendKeys(title);
        Hooks.driver.findElement(AppiumBy.accessibilityId("addRelease.genreField")).sendKeys(genre);
        Hooks.driver.findElement(AppiumBy.accessibilityId("addRelease.saveButton")).click();
    }

    @Then("I see the release {string} in the collection")
    public void iSeeTheRelease(String artist) {
        boolean found = Hooks.driver.findElement(AppiumBy.iOSNsPredicateString(
                "label == '" + artist + "'")).isDisplayed();
        assertTrue(found);
    }
}