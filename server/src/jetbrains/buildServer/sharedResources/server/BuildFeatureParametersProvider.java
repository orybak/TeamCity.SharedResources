package jetbrains.buildServer.sharedResources.server;

import jetbrains.buildServer.serverSide.SBuild;
import jetbrains.buildServer.serverSide.SBuildFeatureDescriptor;
import jetbrains.buildServer.serverSide.SBuildType;
import jetbrains.buildServer.serverSide.parameters.AbstractBuildParametersProvider;
import jetbrains.buildServer.serverSide.parameters.BuildParametersProvider;
import jetbrains.buildServer.sharedResources.SharedResourcesPluginConstants;
import org.jetbrains.annotations.NotNull;

import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * Class {@code BuildFeatureParametersProvider}
 *
 * Exposes {@code SharedResourcesBuildFeature} parameters to build
 *
 * @see SharedResourcesBuildFeature
 * @author Oleg Rybak (oleg.rybak@jetbrains.com)
 */
public class BuildFeatureParametersProvider extends AbstractBuildParametersProvider implements BuildParametersProvider {

  @NotNull
  @Override
  public Map<String, String> getParameters(@NotNull SBuild build, boolean emulationMode) {
    Map<String, String> result;
    if (emulationMode) {
      result = Collections.emptyMap();
    } else {
      result = new HashMap<String, String>();
      final SBuildType buildType = build.getBuildType();
      if (buildType != null) {
        Collection<SBuildFeatureDescriptor> features = buildType.getBuildFeatures();
        for (SBuildFeatureDescriptor descriptor: features) {
          if (SharedResourcesPluginConstants.FEATURE_TYPE.equals(descriptor.getType())) {
            final String serializedBuildParams = descriptor.getParameters().get(SharedResourcesPluginConstants.LOCKS_FEATURE_PARAM_KEY);
            result.putAll(SharedResourcesUtils.featureParamToBuildParams(serializedBuildParams));
          }
        }
      }
    }
    return result;
  }
}
