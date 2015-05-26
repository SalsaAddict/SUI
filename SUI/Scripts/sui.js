"use strict";
angular.module("sui", [
    "ngRoute",
    "ngMessages",
    "ngStorage",
    "ui.bootstrap",
    "templates/suiPopup.html",
    "templates/suiLogin.html",
    "templates/suiTransclude.html",
    "templates/suiForm.html",
    "templates/suiFormContent.html",
    "templates/suiFormLabel.html",
    "templates/suiValidator.html"
])

.run(["$rootScope", "$location", "$routeParams", "$modal", "$localStorage", function ($rootScope, $location, $routeParams, $modal, $localStorage) {
    var modalLogin = undefined;
    function popup(faIcon, iconContext, message) {
        var popupDelay = 2000;
        var modalSuccess = $modal.open({
            size: (message) ? ((message.length <= 50) ? "sm" : "lg") : "sm",
            backdrop: "static",
            templateUrl: "templates/suiPopup.html",
            resolve: { config: function () { return { faIcon: faIcon, iconContext: iconContext, message: message } } },
            controller: ["$scope", "$timeout", "$modalInstance", "config", function ($scope, $timeout, $modalInstance, config) {
                $scope.faIcon = config.faIcon;
                $scope.iconContext = config.iconContext;
                $scope.message = config.message;
                $timeout(function () { $modalInstance.dismiss(); }, popupDelay);
            }]
        });
    }
    $rootScope.$localStorage = $localStorage;
    $rootScope.popupInfo = function (message) { popup("info-circle", "primary", message); }
    $rootScope.popupSuccess = function (message) { popup("check-circle", "success", message); }
    $rootScope.popupError = function (message) { popup("exclamation-triangle", "danger", message); }
    $rootScope.loggedIn = ($rootScope.$localStorage.token) ? true : false;
    $rootScope.login = function (message) {
        if (!angular.isDefined(modalLogin)) {
            modalLogin = $modal.open({
                backdrop: "static",
                templateUrl: "templates/suiLogin.html",
                resolve: { message: function () { return message; } },
                controller: ["$scope", "$http", "$modalInstance", "message", function ($scope, $http, $modalInstance, message) {
                    $scope.message = message;
                    $scope.password = null;
                    $scope.cancel = function () { $modalInstance.close(); }
                    $scope.login = function () {
                        $http.post("login.ashx", { email: $scope.$localStorage.email, password: $scope.password })
                            .success(function (data) {
                                if (data.success === true) {
                                    $scope.$localStorage.token = data.data.token;
                                    $modalInstance.close(true);
                                    $rootScope.popupSuccess("You are now logged in");
                                    $rootScope.$broadcast("sui.login.success");
                                    $rootScope.loggedIn = true;
                                }
                                else {
                                    $scope.$localStorage.token = null;
                                    $modalInstance.close(false);
                                    $rootScope.popupError(data.error);
                                    $rootScope.$broadcast("sui.login.error");
                                    $rootScope.loggedIn = false;
                                }
                            });
                    }
                }]
            }).result.then(function () { modalLogin = undefined; });
        }
    }
    $rootScope.logout = function (notify) {
        $rootScope.$localStorage.token = null;
        $rootScope.$broadcast("sui.logout");
        $rootScope.loggedIn = false;
        if (notify === true) { $rootScope.popupInfo("You have been logged out"); $location.path("/home"); }
    }
    $rootScope.changeRoute = function (route) { $location.path(route); }
    $rootScope.routeParam = function (param) { return $routeParams[param]; }
}])

.directive("sui", ["$log", "$routeParams", "$parse", "$http", function ($log, $routeParams, $parse, $http) {
    return {
        restrict: "E",
        templateUrl: "templates/suiTransclude.html",
        transclude: true,
        replace: true,
        scope: {},
        controller: ["$scope", function ($scope) {
            var self = this, modalLogin = undefined;
            self.procedures = $scope.procedures = {};
            self.addProcedure = function (name, procedure) { $scope.procedures[name] = procedure; }
            self.execute = $scope.execute = function (name) {
                if ($scope.$parent.loggedIn !== true) { $log.warn("sui:execute:not logged in"); return; }
                var procedure = $scope.procedures[name], hasRequired = true;
                var post = { name: procedure.name, parameters: [], type: procedure.type, token: $scope.$parent.$localStorage.token };
                angular.forEach(procedure.parameters, function (item) {
                    var parameter = { name: item.name };
                    switch (item.type) {
                        case "route": parameter.value = $routeParams[item.value]; break;
                        case "scope": parameter.value = $parse(item.value)($scope.$parent); break;
                        case "now": parameter.value = new Date.now();
                        default: parameter.value = item.value; break;
                    }
                    parameter.xml = angular.isObject(parameter.value);
                    if (parameter.xml === true) parameter.value = { data: parameter.value };
                    post.parameters.push(parameter);
                    if (item.required === true) { if (parameter.value === undefined || parameter.value === null || parameter.value === "") hasRequired = false; }
                });
                function empty() { return (angular.isDefined(procedure.model) ? ((procedure.type === "array") ? [] : {}) : null); }
                if (angular.isDefined(procedure.model)) $parse(procedure.model).assign($scope.$parent, empty());
                if (hasRequired === true) {
                    $log.debug(JSON.stringify(post));
                    return $http.post("exec.ashx", post)
                        .success(function (data) {
                            if (data.success === true) {
                                if (angular.isDefined(procedure.model)) {
                                    var transform = (data.data) ? ((procedure.type === "singleton") ? data.data[0] : data.data) : empty();
                                    if (procedure.type === "object") { if (procedure.root) transform = transform[procedure.root]; }
                                    $parse(procedure.model).assign($scope.$parent, transform);
                                }
                            }
                            else {
                                if (data.reauthenticate) { $scope.$parent.logout(); $scope.$parent.login(data.error); }
                                else $scope.$parent.popupError(data.error);
                            }
                        })
                        .error(function (response) { $scope.$parent.popupError(response); });
                }
            }
        }],
        require: "sui",
        link: function (scope, iElement, iAttrs, controller) {
            angular.forEach(scope.procedures, function (procedure, name) {
                if (procedure.run !== "manual") controller.execute(name);
                if (procedure.run === "auto") {
                    angular.forEach(procedure.parameters, function (parameter) {
                        if (parameter.type === "scope") {
                            scope.$parent.$watch(parameter.value, function (newValue, oldValue) {
                                if (newValue !== oldValue) controller.execute(name);
                            });
                        }
                    })
                }
            })
        }
    }
}])

.directive("suiProc", ["$log", function ($log) {
    return {
        restrict: "E",
        templateUrl: "templates/suiTransclude.html",
        transclude: true,
        replace: true,
        scope: { name: "@", alias: "@", model: "@", type: "@", root: "@", run: "@" },
        controller: ["$scope", function ($scope) {
            if (!$scope.name) $log.error("suiProc:required:name");
            if (!$scope.alias) $scope.alias = $scope.name;
            $scope.procedure = { name: $scope.name, parameters: [] };
            if ($scope.model) {
                $scope.procedure.model = $scope.model;
                $scope.procedure.type = angular.lowercase($scope.type);
                if (["singleton", "object"].indexOf($scope.procedure.type) < 0) $scope.procedure.type = "array";
                if ($scope.procedure.type === "object") { if ($scope.root) $scope.procedure.root = $scope.root };
            } else $scope.procedure.type = "execute";
            $scope.procedure.run = angular.lowercase($scope.run);
            if (["auto", "once"].indexOf($scope.procedure.run) < 0) $scope.procedure.run = "manual";
            this.addParameter = function (parameter) { $scope.procedure.parameters.push(parameter); }
        }],
        require: "^^sui",
        link: function (scope, iElement, iAttrs, controller) { controller.addProcedure(scope.alias, scope.procedure); }
    }
}])

.directive("suiProcParam", [function () {
    return {
        restrict: "E",
        templateUrl: "templates/suiTransclude.html",
        transclude: true,
        replace: true,
        scope: { name: "@", type: "@", value: "@", required: "@" },
        controller: ["$scope", function ($scope) {
            $scope.parameter = {
                name: $scope.name,
                type: angular.lowercase($scope.type),
                value: $scope.value,
                required: ($scope.required === "true")
            }
            if (["route", "scope", "now"].indexOf($scope.parameter.type) < 0) $scope.parameter.type = "value";
            if (!$scope.parameter.value) { if ($scope.parameter.type !== "value") $scope.parameter.value = $scope.parameter.name };
        }],
        require: "^^suiProc",
        link: function (scope, iElement, iAttrs, controller) { controller.addParameter(scope.parameter); }
    }
}])

.directive("suiForm", ["$route", "$location", "$window", function ($route, $location, $window) {
    return {
        restrict: "E",
        templateUrl: "templates/suiForm.html",
        transclude: true,
        replace: true,
        scope: { heading: "@", backRoute: "@back", deleteProcName: "@delete", saveProcName: "@save" },
        require: "^^sui",
        controller: ["$scope", function ($scope) {
            var self = this;
            self.tabs = $scope.tabs = [];
            self.addTab = $scope.addTab = function (heading) {
                var index = $scope.tabs.length;
                var tab = { index: index, heading: (heading) ? heading : "Tab " + (index + 1), active: (index == 0) }
                $scope.tabs.push(tab);
                return tab;
            }
            self.tabbed = $scope.tabbed = function () { return ($scope.tabs.length > 1); }
            self.activateTab = $scope.activateTab = function (tabToActivate) { angular.forEach($scope.tabs, function (tab) { tab.active = (tab === tabToActivate) }); }
            self.deletable = $scope.deletable = function () { return ($scope.delete) ? true : false; }
            self.editable = $scope.editable = function () { return ($scope.saveProcName) ? true : false; }
            self.hasError = $scope.hasError = function () { return $scope.form.$dirty && $scope.form.$invalid; }
            self.back = $scope.back = function () { if ($scope.backRoute) $location.path($scope.backRoute); else $window.history.back(); }
            self.undo = $scope.undo = function () { $route.reload(); }
            $scope.$on("sui.form.dirty", function () { $scope.form.$setDirty(); });
        }],
        link: function (scope, iElement, iAttrs, controller) {
            if (scope.deletable()) scope.delete = function () { return controller.execute(scope.deleteProcName); }
            if (scope.editable()) scope.save = function () {
                controller.execute(scope.saveProcName)
                    .success(function (data) {
                        if (data.success === true) {
                            scope.$parent.popupSuccess("Your changes have been saved");
                            if (angular.isArray(data.data)) {
                                var params = {};
                                angular.forEach(data.data[0], function (value, key) { params[key] = value; });
                                $route.updateParams(params);
                            }
                        }
                    });
            }
        }
    }
}])

.directive("suiFormSave", ["$log", function ($log) {
    return {
        restrict: "E",
        templateUrl: "templates/suiTransclude.html",
        transclude: true,
        replace: true,
        scope: { procName: "@proc", faIcon: "@", buttonText: "@" },
        require: "^^suiForm",
        link: function (scope, iElement, iAttrs, controller) {
            if (!scope.procName) $log.error("suiFormSave:required:procName");
            controller.enableSave({
                procName: scope.procName,
                faIcon: (scope.faIcon) ? scope.faIcon : "save",
                buttonText: (scope.buttonText) ? scope.buttonText : "Save"
            });
        }
    }
}])

.directive("suiFormContent", [function () {
    return {
        restrict: "E",
        templateUrl: "templates/suiFormContent.html",
        transclude: true,
        replace: true,
        scope: { heading: "@" },
        require: "^^suiForm",
        controller: ["$scope", function ($scope) { }],
        link: function (scope, iElement, iAttrs, controller) {
            scope.tab = controller.addTab(scope.heading);
            scope.tabbed = function () { return controller.tabbed(); }
            scope.editable = function () { return controller.editable(); }
            scope.tab.hasError = function () { return controller.hasError() && scope.form.$invalid; }
        }
    }
}])

.directive("suiFormLabel", [function () {
    return {
        restrict: "E",
        templateUrl: "templates/suiFormLabel.html",
        transclude: true,
        replace: true,
        scope: { heading: "@" },
        require: ["?^^suiForm", "?^^form"],
        controller: ["$scope", function ($scope) {
            $scope.validatorMessages = [];
            this.addValidatorMessage = function (name, message) {
                $scope.validatorMessages.push({ name: name, message: message });
            }
        }],
        link: function (scope, iElement, iAttrs, controller) {
            scope.showMessages = function () { return !angular.isDefined(iAttrs["nomsg"]); }
            scope.hasError = function () { return ((controller[0]) ? controller[0].hasError() : ((controller[1]) ? controller[1].$dirty : scope.form.$dirty)) && scope.form.$invalid; }
        }
    }
}])

.directive("suiValidator", [function () {
    return {
        restrict: "E",
        templateUrl: "templates/suiValidator.html",
        replace: true,
        transclude: true,
        scope: { name: "@", fn: "&function", message: "@" },
        require: "^^suiFormLabel",
        controller: ["$scope", function ($scope) {
            $scope.value = function () { return ($scope.fn() === true) ? true : null; }
        }],
        link: function (scope, iElement, iAttrs, controller) {
            controller.addValidatorMessage(scope.name, scope.message);
            scope.form.model.$validators[scope.name] = function () { return scope.fn(); }
        }
    }
}])

.directive("suiFormControl", ["$filter", function ($filter) {
    return {
        restrict: "A",
        require: ["ngModel"],
        link: function (scope, iElement, iAttrs, controller) {
            if (iAttrs["type"] !== "checkbox") if (!iElement.hasClass("form-control")) iElement.addClass("form-control");
            if (iAttrs["type"] === "date") {
                controller[0].$formatters.push(function (modelValue) { return new Date(modelValue); });
                controller[0].$parsers.push(function (modelValue) { return (modelValue) ? $filter("date")(new Date(modelValue), "yyyy-MM-dd") : null; });
            }
            if (iAttrs["suiFormControl"]) {
                switch (angular.lowercase(iAttrs["suiFormControl"])) {
                    case "percent":
                        if (!iElement.hasClass("text-right")) iElement.addClass("text-right");
                        controller[0].$formatters.push(function (modelValue) { return parseInt(parseFloat(modelValue) * 100); });
                        controller[0].$parsers.push(function (modelValue) { return parseFloat($filter("number")(parseFloat(modelValue) / 100, 2)); });
                        break;
                }
            }
        }
    }
}]);

angular.module("templates/suiPopup.html", []).run(["$templateCache", function ($templateCache) {
    $templateCache.put("templates/suiPopup.html",
        "<div class=\"modal-body\"><i class=\"fa fa-lg fa-{{faIcon}} text-{{iconContext}}\"></i> {{message}}</div>");
}]);

angular.module("templates/suiLogin.html", []).run(["$templateCache", function ($templateCache) {
    $templateCache.put("templates/suiLogin.html",
        "<ng-form name=\"loginForm\" class=\"form-horizontal\">" +
        "<div class=\"modal-header\"><h4 class\"modal-title\">Login</h4></div>" +
        "<div class=\"modal-body\">" +
        "<alert type=\"danger\" ng-if=\"message\">{{message}}</alert>" +
        "<div class=\"form-group\" ng-class=\"{'has-error': loginForm.$dirty && loginForm.email.$invalid}\">" +
        "<label class=\"control-label col-sm-3\">Email Address</label>" +
        "<div class=\"col-sm-9\">" +
        "<input type=\"email\" name=\"email\" class=\"form-control\" ng-model=\"$localStorage.email\" required />" +
        "</div></div>" +
        "<div class=\"form-group\" ng-class=\"{'has-error': loginForm.$dirty && loginForm.password.$invalid}\">" +
        "<label class=\"control-label col-sm-3\">Password</label>" +
        "<div class=\"col-sm-9\">" +
        "<input type=\"password\" name=\"password\" class=\"form-control\" ng-model=\"password\" required />" +
        "</div></div></div>" +
        "<div class=\"modal-footer\">" +
        "<button type=\"button\" class=\"btn btn-default\" ng-click=\"cancel()\">Cancel</button>&nbsp;" +
        "<button type=\"submit\" class=\"btn\" ng-class=\"{'btn-primary': loginForm.$valid, 'btn-default': loginForm.$invalid}\" ng-disabled=\"loginForm.$invalid\" ng-click=\"login()\">" +
        "<i class=\"fa fa-lock\"></i> Login</button>" +
        "</div>" +
        "</ng-form>");
}]);

angular.module("templates/suiTransclude.html", []).run(["$templateCache", function ($templateCache) {
    $templateCache.put("templates/suiTransclude.html", "<ng-transclude></ng-transclude>");
}]);

angular.module("templates/suiForm.html", []).run(["$templateCache", function ($templateCache) {
    $templateCache.put("templates/suiForm.html",
        "<div class=\"panel panel-default form-horizontal\" ng-form=\"form\">" +
        "<div class=\"panel-heading\"><h4><b>{{heading}}</b>" +
        "<span class=\"text-danger\" ng-show=\"hasError()\">&nbsp;<i class=\"fa fa-exclamation-triangle\" title=\"There are errors on this form\"></i></span>" +
        "</h4></div>" +
        "<div class=\"panel-body\"><div class=\"tabpanel\">" +
        "<ul class=\"nav nav-tabs\" ng-if=\"tabbed()\">" +
        "<li ng-repeat=\"tab in tabs\" ng-class=\"{active: tab.active}\">" +
        "<a href ng-click=\"activateTab(tab)\">{{tab.heading}}" +
        "<span class=\"text-danger\" ng-show=\"tab.hasError()\">&nbsp;<i class=\"fa fa-exclamation-triangle\" title=\"There are errors on this tab\"></i></span>" +
        "</a></li></ul>" +
        "<div class=\"tab-content\" ng-transclude></div>" +
        "</div></div>" +
        "<div class=\"panel-footer clearfix\">" +
        "<div class=\"pull-right\">" +
        "<div ng-hide=\"form.$dirty\">" +
        "<button type=\"button\" class=\"btn btn-danger\" ng-if=\"deletable()\"><i class=\"fa fa-trash-o\"></i> Delete</button>&nbsp;" +
        "<button type=\"button\" class=\"btn btn-default\" ng-click=\"back()\"><i class=\"fa fa-chevron-circle-left\"></i> Back</button>" +
        "</div>" +
        "<div ng-show=\"form.$dirty\">" +
        "<button type=\"button\" class=\"btn btn-warning\" ng-click=\"undo()\"><i class=\"fa fa-undo\"></i> Undo</button>&nbsp;" +
        "<button type=\"button\" class=\"btn\" ng-class=\"{'btn-primary': !hasError(), 'btn-default': hasError()}\" ng-disabled=\"form.$invalid\" ng-click=\"save()\"><i class=\"fa fa-save\"></i> Save</button>" +
        "</div></div></div></div>");
}]);

angular.module("templates/suiFormContent.html", []).run(["$templateCache", function ($templateCache) {
    $templateCache.put("templates/suiFormContent.html",
        "<div class=\"tab-pane\" ng-class=\"{active: tab.active}\">" +
        "<br ng-if=\"tabbed()\" />" +
        "<fieldset ng-disabled=\"!editable()\" ng-form=\"form\" ng-transclude></fieldset>" +
        "</div>");
}]);

angular.module("templates/suiFormLabel.html", []).run(["$templateCache", function ($templateCache) {
    $templateCache.put("templates/suiFormLabel.html",
        "<div class=\"form-group\" ng-class=\"{'has-error': hasError()}\" ng-form=\"form\">" +
        "<label class=\"control-label col-sm-3\">{{heading}}</label>" +
        "<div class=\"col-sm-9\">" +
        "<ng-transclude></ng-transclude>" +
        "<div ng-messages=\"form.$error\" class=\"help-block\" ng-if=\"showMessages()\" ng-show=\"hasError()\">" +
        "<div ng-message=\"required\">This field is required</div>" +
        "<div ng-message=\"email\">This is not a valid email address</div>" +
        "<div ng-repeat=\"message in validatorMessages\" ng-message=\"{{message.name}}\">{{message.message}}</div>" +
        "</div></div></div>");
}]);

angular.module("templates/suiValidator.html", []).run(["$templateCache", function ($templateCache) {
    $templateCache.put("templates/suiValidator.html", "<ng-form name=\"form\">" +
        "<input type=\"hidden\" name=\"model\" ng-model=\"value()\" ng-model-options=\"{ getterSetter: true }\" />" +
        "</ng-form>");
}]);