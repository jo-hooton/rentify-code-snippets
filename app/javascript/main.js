$(document).ready(function () {
  tenantModalRedirectAndErrors();
  deleteRedirectAndErrors();
});

function getFormIds() {
  var formIds = [];
  var modals = document.querySelectorAll(".modal-body");
  modals.forEach((modal) =>
    modal.dataset.tenantId
      ? formIds.push(
          `#edit_user_${modal.dataset.userId}`,
          `#edit_tenant_${modal.dataset.tenantId}`
        )
      : formIds.push("#new_user")
  );
  return formIds;
}

function tenantModalRedirectAndErrors() {
  var formIds = getFormIds();
  formIds.forEach((formId) => {
    $(document)
      .on("ajax:success", formId, function (event, data) {
        window.location.pathname = data.redirect_path;
      })
      .on("ajax:error", formId, function (event, data) {
        var form = document.querySelector(formId);
        form
          .querySelectorAll(".error")
          .forEach((e) => e.parentNode.removeChild(e));
        _.each(data.responseJSON.errors, function (error, name) {
          if (name === "tenants.email") {
            var className = " .user_email";
          } else {
            var className = " .user_" + name;
          }
          var div = document.createElement("div");
          div.className = "error";
          div.innerText = error;
          var element = form.querySelector(className);
          if (element) {
            element.appendChild(div);
          }
        });
      });
  });
}

function deleteRedirectAndErrors() {
  var formIds = getFormIds();
  formIds.forEach((formId) => {
    if (formId.includes("edit_tenant")) {
      $(formId)
        .on("ajax:success", function (event, data) {
          window.location.pathname = data.redirect_path;
        })
        .on("ajax:error", function (event, data) {
          var error = data.responseJSON.errors;
          var div = document.createElement("div");
          div.className = "error";
          div.innerText = error;
          var element = document.querySelector(formId);
          if (element) {
            element.appendChild(div);
          }
        });
    }
  });
}
