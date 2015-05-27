angular.module("advent", ["ngRoute", "sui"])

.config(["$routeProvider", function ($routeProvider) {
    $routeProvider
        .when("/home", { caseInsensitiveMatch: true, templateUrl: "Views/home.html" })
        .when("/companies", { caseInsensitiveMatch: true, templateUrl: "Views/companies.html" })
        .when("/company/:CompanyId?", { caseInsensitiveMatch: true, templateUrl: "Views/company.html" })
        .when("/binders", { caseInsensitiveMatch: true, templateUrl: "Views/binders.html" })
        .when("/binder/:BinderId?", { caseInsensitiveMatch: true, templateUrl: "Views/binder.html" })
        .when("/binder/:BinderId/section/:SectionId?", { caseInsensitiveMatch: true, templateUrl: "Views/bindersection.html", controller: "BinderSectionController" })
        .when("/incidents", { caseInsensitiveMatch: true, templateUrl: "Views/incidents.html" })
        .when("/incident/:IncidentId?", { caseInsensitiveMatch: true, templateUrl: "Views/incident.html", controller: "IncidentController" })
        .when("/incident/:IncidentId/claimant/:ClaimantId?", { caseInsensitiveMatch: true, templateUrl: "Views/claimant.html" })
        .when("/incident/:IncidentId/claimant/:ClaimantId/claim/:ClaimId?", { caseInsensitiveMatch: true, templateUrl: "Views/claim.html" })
        .otherwise({ redirectTo: "/home" });
}])

.run(["$rootScope", function ($rootScope) {
    $rootScope.navBarCollapsed = true;
    $rootScope.$on("$routeChangeSuccess", function () { $rootScope.navBarCollapsed = true; });
}])

.controller("BinderSectionController", ["$scope", function ($scope) {
    function reindex() { var Index = 0; angular.forEach($scope.Section.Carriers, function (Item) { Item.Index = Index; Index++; }); };
    $scope.CarrierLabel = function (Index) {
        switch (Index) {
            case 0: return "Lead"; break;
            case 1: return "Second"; break;
            default: return "Other"; break;
        }
    }
    $scope.RemoveCarrier = function (Item) {
        var Index = $scope.Section.Carriers.indexOf(Item);
        $scope.Section.Carriers.splice(Index, 1); reindex();
        $scope.$broadcast("sui.form.dirty");
    }
    $scope.AddCarrier = function () {
        if (!angular.isDefined($scope.Section.Carriers)) $scope.Section.Carriers = [];
        $scope.Section.Carriers.push({ CarrierId: null, Percentage: 0 }); reindex();
        $scope.$broadcast("sui.form.dirty");
    }
    $scope.RemoveExpert = function (Item) {
        var Index = $scope.Section.Carriers.indexOf(Item);
        $scope.Section.Carriers.splice(Index, 1);
        $scope.$broadcast("sui.form.dirty");
    }
    $scope.AddExpert = function () {
        if (!angular.isDefined($scope.Section.Experts)) $scope.Section.Experts = [];
        $scope.Section.Experts.push({ ExpertId: null, ExpertTypeId: null, Description: null });
        $scope.$broadcast("sui.form.dirty");
    }
    $scope.Total = function () {
        var Total = 0; angular.forEach($scope.Section.Carriers, function (Item) { Total += parseFloat(Item.Percentage); });
        return Total;
    }
    $scope.CheckTotal = function () { return ($scope.Total() === 1); }
}])

.controller("IncidentController", ["$scope", function ($scope) {
    $scope.DateBrokerAdvisedValidator = function () {
        return ($scope.Incident.DateIncident && $scope.Incident.DateBrokerAdvised) ?
            (new Date($scope.Incident.DateIncident) <= new Date($scope.Incident.DateBrokerAdvised)) : true;
    }
    $scope.DateTPANotifiedValidator = function () {
        return ($scope.Incident.DateBrokerAdvised && $scope.Incident.DateTPANotified) ?
            (new Date($scope.Incident.DateBrokerAdvised) <= new Date($scope.Incident.DateTPANotified)) : true;
    }
    $scope.DateIncidentValidator = function () {
        var valid = true;
        if ($scope.Incident.DateIncident) {
            if ($scope.Incident.PolicyInceptionDate) {
                if (new Date($scope.Incident.DateIncident) < new Date($scope.Incident.PolicyInceptionDate)) valid = false;
            }
            if ($scope.Incident.PolicyExpiryDate) {
                if (new Date($scope.Incident.DateIncident) > new Date($scope.Incident.PolicyExpiryDate)) valid = false;
            }
        }
        return valid;
    }
    $scope.PolicyExpiryDateValidator = function () {
        return ($scope.Incident.PolicyInceptionDate && $scope.Incident.PolicyExpiryDate) ?
            (new Date($scope.Incident.PolicyInceptionDate) <= new Date($scope.Incident.PolicyExpiryDate)) : true;
    }
}]);

