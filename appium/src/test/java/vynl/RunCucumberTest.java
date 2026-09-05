package vynl;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectClasspathResource;
import org.junit.platform.suite.api.Suite;

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;

@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("features")
// Explicit glue packages. Scanning is recursive, so "vynl" would still find
// these, but a silent glue miss surfaces as "0 scenarios" and is miserable to
// debug — name them.
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "vynl.hooks,vynl.steps")
public class RunCucumberTest {
}