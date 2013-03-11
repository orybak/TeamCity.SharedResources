<%--
  ~ Copyright 2000-2013 JetBrains s.r.o.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  --%>
<%@ include file="/include-internal.jsp" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="jetbrains.buildServer.sharedResources.SharedResourcesPluginConstants" %>
<%@ page import="jetbrains.buildServer.sharedResources.server.feature.FeatureParams" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>

<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="keys" class="jetbrains.buildServer.sharedResources.SharedResourcesPluginConstants"/>
<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<jsp:useBean id="locks" scope="request"
             type="java.util.Map<java.lang.String, jetbrains.buildServer.sharedResources.model.Lock>"/>
<jsp:useBean id="bean" scope="request" type="jetbrains.buildServer.sharedResources.pages.SharedResourcesBean"/>
<jsp:useBean id="inherited" scope="request" type="java.lang.Boolean"/>

<c:set var="locksFeatureParamKey" value="<%=FeatureParams.LOCKS_FEATURE_PARAM_KEY%>"/>
<c:set var="PARAM_RESOURCE_NAME" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_NAME%>"/>
<c:set var="PARAM_PROJECT_ID" value="<%=SharedResourcesPluginConstants.WEB.PARAM_PROJECT_ID%>"/>
<c:set var="PARAM_RESOURCE_TYPE" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_TYPE%>"/>
<c:set var="PARAM_RESOURCE_QUOTA" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_QUOTA%>"/>

<script type="text/javascript">

BS.LocksUtil = {

  locksDisplay: {
    readLock: "Read Lock",
    writeLock: "Write Lock"
  },

  lockToString: function (lock) {
    return lock.name + " " + lock.type + " " + (lock.value ? lock.value : "") + "\n";
  },

  lockToTableRow: function (lock) {
    var resource = BS.SharedResourcesFeatureDialog.resources[lock.name];
    var result = {};
    result.name = lock.name;
    if (resource.type == 'CUSTOM') {
      if (lock.type == 'readLock') {
        result.description = "Any Value";
      } else {
        if (lock.value) {
          result.description = "Specific Value: " + lock.value;
        } else {
          result.description = "ALL Values";
        }
      }
    } else {
      result.description = this.locksDisplay[lock.type];
    }
    return result;
  }
};

/**
 * Data container for resources and locks
 *
 * Deals with table of locks, calls dialog for add/edit
 *
 * @type {{resources: {}, locks: {}}}
 */
BS.SharedResourcesFeatureDialog = {
  resources: {}, // map of resources: <resource_name, Resource>
  locks: {}, // map of locks: <lock_name, Lock>
  inherited: false,

  refreshUI: function () {
    var tableBody = $j('#locksTaken tbody:last');
    var textArea = $j('#${locksFeatureParamKey}');
    tableBody.children().remove();
    var locks = this.locks;
    var textAreaContent = "";
    //noinspection JSUnresolvedVariable
    var size = _.size(locks);
    if (size > 0) { // we have some locks
      for (var key in locks) {
        if (locks.hasOwnProperty(key)) {
          var od, deleteCell;
          var oc, editCell;
          var hClass;
          if (this.inherited) {
            oc = '';
            od = '';
            hClass = '';
            editCell = $j('<td>').attr('class', 'edit').append($j('<span>').attr('style', 'white-space: nowrap;').text('cannot be edited'));
            deleteCell = $j('<td>').attr('class', 'edit').text('undeletable');
          } else {
            oc = 'BS.LocksDialog.showEdit(\"' + key + '\"); return false;';
            od = 'BS.SharedResourcesFeatureDialog.deleteLock(\"' + key + '\"); return false;';
            hClass = 'highlight';
            editCell = $j('<td>').attr('class', 'edit ' + hClass).attr('style', 'width: 10%').attr('onclick', oc).append($j('<a>').attr('href', '#').attr('onclick', oc).text('edit'));
            deleteCell = $j('<td>').attr('class', 'edit').attr('style', 'width: 10%').append($j('<a>').attr('href', '#').attr('onclick', od).text('delete'));
          }
          textAreaContent += BS.LocksUtil.lockToString(locks[key]);
          var tableRow = BS.LocksUtil.lockToTableRow(locks[key]);
          //noinspection JSCheckFunctionSignatures
          tableBody.append($j('<tr>').attr('style', 'border-top: 1px solid #CCC')
                  .append($j('<td>').attr('class', hClass).text(tableRow.name).attr('onclick', oc))
                  .append($j('<td>').attr('class', hClass).text(tableRow.description).attr('onclick', oc))
                  .append(editCell)
                  .append(deleteCell)
          );
        }
      }
      this.rehighlight();
      BS.Util.show('locksTaken');
      BS.Util.hide('noLocksTaken');
    } else { // no locks are taken
      BS.Util.hide('locksTaken');
      BS.Util.show('noLocksTaken');
    }
    //noinspection JSUnresolvedFunction
    textArea.val(textAreaContent.trim());
    BS.MultilineProperties.updateVisible();
  },

  rehighlight: function () {
    var hElements = $j("#locksTaken td.highlight");
    hElements.each(function (i, element) {
      BS.TableHighlighting.createInitElementFunction.call(this, element, 'Click to edit lock');
    });
  },

  deleteLock: function (lockName) {
    delete this.locks[lockName];
    this.refreshUI();
  }
};

//noinspection JSUnusedGlobalSymbols
/**
 * Dialog for adding/editing locks
 * @type {*}
 */
BS.LocksDialog = OO.extend(BS.AbstractModalDialog, {
  attachedToRoot: false,
  availableResources: {},
  currentLockName: "",

  getContainer: function () {
    return $('locksDialog');
  },

  showDialog: function () {
    this.editMode = false;
    // filter available resources
    this.fillAvailableResources();
    this.fillAvailableResourcesDropdown();
    // sync state (resources / no resources)
    this.displayResourceChooser();
    // sync state (resource type => locks type (quoted => read/write; custom=>ALL/ANY/SPECIFIC))
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));
  },

  showEdit: function (lockName) {
    this.editMode = true;
    this.currentLockName = lockName;
    // select resource
    var currentResource = BS.SharedResourcesFeatureDialog.resources[this.currentLockName];
    // select lock
    var currentLock = BS.SharedResourcesFeatureDialog.locks[this.currentLockName];
    // filter available resources
    this.fillAvailableResources();
    // add current resource to available
    this.availableResources[this.currentLockName] = currentResource;
    // fill dropdown
    this.fillAvailableResourcesDropdown();
    // restore selection
    $j('#lockFromResources option').each(function () {
      var self = $j(this);
      self.prop("selected", self.val() == lockName);
    });
    this.displayResourceChooser();
    this.chooseResource();
    // set values
    if (currentResource.type === 'CUSTOM') {
      var customLockType;
      if (currentLock.type === 'readLock') {
        if (currentLock.value) {
          customLockType = 'SPECIFIC';
        } else {
          customLockType = 'ANY';
        }
      } else {
        customLockType = 'ALL';
      }
      $j('#newCustomLockType option').each(function () {
        var self = $j(this);
        self.prop("selected", self.val() == customLockType);
      }); // restore lock type
      this.chooseCustomLockType();
      if (customLockType === 'SPECIFIC') {
        // restore selection
        $j('#newCustomLockType_Values option').each(function () {
          var self = $j(this);
          self.prop("selected", self.val() == currentLock.value);
        });
      }
    } else { // quoted resource. simply select lock type
      $j('#newLockType option').each(function () {
        var self = $j(this);
        self.prop("selected", self.val() == currentLock.type);
      }); // restore lock type
    }
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));
  },

  fillAvailableResourcesDropdown: function () {
    var resourceDropdown = $j('#lockFromResources');
    resourceDropdown.children().remove();
    for (var key in this.availableResources) {
      if (this.availableResources.hasOwnProperty(key)) {
        //noinspection JSCheckFunctionSignatures
        resourceDropdown.append("<option value='" + this.availableResources[key].name + "'>" + this.availableResources[key].name + "</option>");
      }
    }
  }, /**
   * Filters resources that will be available for resource chooser
   */
  fillAvailableResources: function () {
    this.availableResources = {};
    var resources = BS.SharedResourcesFeatureDialog.resources;
    var locks = BS.SharedResourcesFeatureDialog.locks;
    for (var key in resources) {
      if (resources.hasOwnProperty(key) && !locks[key]) { // resource exists but is not used
        this.availableResources[key] = resources[key];
      }
    }
  },

  displayResourceChooser: function () {
    //noinspection JSUnresolvedVariable
    if (_.size(this.availableResources) > 0) {
      BS.Util.show('lockFromResources_Yes');
      BS.Util.hide('lockFromResources_No');
      BS.Util.show('locksDialogSubmit');
      this.chooseResource();
    } else {
      BS.Util.show('lockFromResources_No');
      BS.Util.hide('lockFromResources_Yes');

      BS.Util.hide('row_CustomResource_Type');
      BS.Util.hide('row_QuotedResource_Type');
      BS.Util.hide('row_CustomResource_Value');
      BS.Util.hide('locksDialogSubmit');
    }
  },

  chooseResource: function () {
    // get value of chooser
    var resourceName = $j('#lockFromResources option:selected').val();
    // get resource for value
    var resource = BS.SharedResourcesFeatureDialog.resources[resourceName];
    // get resource type
    if (resource.type == 'QUOTED') {
      BS.Util.show('row_QuotedResource_Type');
      BS.Util.hide('row_CustomResource_Type');
      BS.Util.hide('row_CustomResource_Value');
    } else {
      BS.Util.show('row_CustomResource_Type');
      BS.Util.hide('row_QuotedResource_Type');
      this.chooseCustomLockType();
    }
  },

  chooseCustomLockType: function () {
    var customType = $j('#newCustomLockType option:selected').val();
    if ('SPECIFIC' === customType) {
      BS.Util.show('row_CustomResource_Value');
      this.fillResourceValues();
    } else {
      BS.Util.hide('row_CustomResource_Value');
    }
  },

  fillResourceValues: function () {
    // get value of chooser
    var resourceName = $j('#lockFromResources option:selected').val();
    // get resource for value
    var resource = BS.SharedResourcesFeatureDialog.resources[resourceName];
    var valuesDropdown = $j('#newCustomLockType_Values');
    valuesDropdown.children().remove();
    for (var key in resource.values) {
      if (resource.values.hasOwnProperty(key)) {
        //noinspection JSCheckFunctionSignatures
        valuesDropdown.append("<option value='" + resource.values[key] + "'>" + resource.values[key] + "</option>");
      }
    }
  },

  submit: function () {

    // construct lock
    var lock = {};
    /// get selected resource name
    /// get selected resource
    // get value of chooser
    var resourceName = $j('#lockFromResources option:selected').val();
    // get resource for value
    var resource = BS.SharedResourcesFeatureDialog.resources[resourceName];
    lock.name = resourceName;
    ///
    if (resource.type === 'QUOTED') {
      lock.type = $j('#newLockType option:selected').val();
    } else { // CUSTOM
      var typeName = $j('#newCustomLockType option:selected').val();
      if (typeName === 'ANY') {
        lock.type = "readLock";
      } else if (typeName === 'SPECIFIC') {
        lock.type = "readLock";
        lock.value = $j('#newCustomLockType_Values option:selected').val();
      } else {
        lock.type = "writeLock";
      }
    }
    if (this.editMode) {
      delete BS.SharedResourcesFeatureDialog.locks[this.currentLockName];
    }
    // add to locks
    BS.SharedResourcesFeatureDialog.locks[lock.name] = lock;
    // refresh ui
    BS.SharedResourcesFeatureDialog.refreshUI();
    this.close();
    return false;
  }
});
</script>

<script type="text/javascript">
  var self = BS.SharedResourcesFeatureDialog;
  /* load resources into javaScript */
  var rs = self.resources;
  var rc;

  <c:set var="resourcesMap" value="${bean.allResources}"/>

  <c:forEach var="item" items="${resourcesMap}">
  rc = {};
  rc.name = '${item.name}';
  rc.type = '${item.type}';
  <c:choose>
  <c:when test="${item.type == 'CUSTOM'}">
  rc.values = [];
  <c:forEach var="cr" items="${item.values}">
  rc.values.push('${cr}');
  </c:forEach>
  </c:when>
  <c:when test="${item.type == 'QUOTED'}">
  rc.quota = ${item.quota};
  </c:when>
  </c:choose>
  rs['${item.name}'] = rc; // push resource to map
  </c:forEach>
  /* load locks into javascript */
  var locks = self.locks;
  var lc;
  <c:forEach var="item" items="${locks}">
  lc = {};
  lc.name = '${item.value.name}';
  lc.type = '${item.value.type.name}';
  lc.value = '${item.value.value}';
  locks['${item.value.name}'] = lc;
  </c:forEach>
  self.inherited = ${inherited};

  BS.SharedResourcesFeatureDialog.refreshUI();

</script>

<tr>
  <td colspan="2" style="padding-right: 8px">
    <table id="locksTaken" class="parametersTable">
      <thead>
      <tr>
        <th style="width: 25%">Resource Name</th>
        <th colspan="3" style="width: 75%">Lock Details</th>
      </tr>
      </thead>
      <tbody>
      </tbody>
    </table>
    <span class="smallNote" id="inheritedNote" style="display: none;">This feature is inherited. Locks can be edited in template this feature is inherited from.</span>

    <div id="noLocksTaken" style="display: none">
      No locks are currently defined
    </div>
  </td>
</tr>

<tr style="display: none">
  <th>Locks</th>
  <td>
    <props:multilineProperty name="${locksFeatureParamKey}" linkTitle="names" cols="49" rows="5" expanded="${false}"/>
    <span class="error" id="error_${locksFeatureParamKey}"></span>
  </td>
</tr>

<tr>
  <td class="noBorder" colspan="2">
    <forms:addButton id="addNewLock" onclick="BS.LocksDialog.showDialog(); return false">Add lock</forms:addButton>
    <bs:dialog dialogId="locksDialog" title="Lock Management" closeCommand="BS.LocksDialog.close()">
      <table class="runnerFormTable">
        <tr id="row_resourceChoose">
          <th><label for="lockFromResources">Resource name:</label></th>
          <td>
            <div id="lockFromResources_Yes">
              <forms:select name="lockFromResources" id="lockFromResources" style="width: 90%"
                            onchange="BS.LocksDialog.chooseResource();"/>
              <span class="smallNote">Choose the resource you want to lock</span>
            </div>
            <div id="lockFromResources_No">
              <c:out value="No resources available. Please add the resource you want to lock."/>
            </div>
          </td>
        </tr>

        <tr id="row_QuotedResource_Type">
          <th><label for="newLockType">Lock type:</label></th>
          <td>
            <forms:select name="newLockType" id="newLockType" style="width: 90%">
              <forms:option value="readLock">Read Lock</forms:option>
              <forms:option value="writeLock">Write Lock</forms:option>
            </forms:select>
            <span class="smallNote">Select type of lock: read lock (shared), or write lock (exclusive)</span>
          </td>
        </tr>

        <tr id="row_CustomResource_Type">
          <th>Lock type:</th>
          <td>
            <forms:select name="newCustomLockType" id="newCustomLockType" style="width: 90%"
                          onchange="BS.LocksDialog.chooseCustomLockType(); ">
              <forms:option value="ANY">Lock any value</forms:option>
              <forms:option value="ALL">Lock all values</forms:option>
              <forms:option value="SPECIFIC">Lock specific value</forms:option>
            </forms:select>
            <span class="smallNote">Select type of lock on custom resource: any available value, all values or specify value you want to lock</span>
          </td>
        </tr>

        <tr id="row_CustomResource_Value">
          <th>Value to lock:</th>
          <td>
            <forms:select name="newCustomLockType_Values" id="newCustomLockType_Values" style="width: 90%"/>
            <span class="smallNote">Choose value of custom resource to lock</span>
          </td>
        </tr>

      </table>
      <div class="popupSaveButtonsBlock">
        <forms:cancel onclick="BS.LocksDialog.close()" showdiscardchangesmessage="false"/>
        <forms:submit id="locksDialogSubmit" type="button" label="Add Lock" onclick="BS.LocksDialog.submit();"/>
      </div>
    </bs:dialog>
  </td>
</tr>
