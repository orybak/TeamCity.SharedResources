/*
 * Copyright 2000-2013 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package jetbrains.buildServer.sharedResources.server.feature;

import jetbrains.buildServer.serverSide.SBuild;
import jetbrains.buildServer.sharedResources.model.Lock;
import org.jetbrains.annotations.NotNull;

import java.util.Map;

/**
 * Interface {@code LocksStorage}
 *
 * Contains method definition for taken locks storage
 *
 * @author Oleg Rybak (oleg.rybak@jetbrains.com)
 */
public interface LocksStorage {

  /**
   * Stores taken locks for given build
   *
   * @param build build to store locks for
   * @param takenLocks taken locks for given build with values
   */
  public void store(@NotNull final SBuild build, @NotNull final Map<Lock, String> takenLocks);


  /**
   * Loads taken locks
   *
   *
   * @param build build to load locks for
   * @return map in format {@code LockName -> LockValue}
   */
  @NotNull
  public Map<Lock, String> load(@NotNull final SBuild build);

}