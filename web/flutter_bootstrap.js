{{flutter_js}}
{{flutter_build_config}}

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    for (const registration of registrations) {
      registration.unregister();
    }
  });
}

const boot = document.getElementById("boot");
const bootTimer = window.setTimeout(() => {
  if (boot) {
    boot.textContent =
      "불러오기가 지연되고 있습니다. 화면을 새로고침 해 주세요.";
  }
}, 15000);

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
    renderer: "canvaskit",
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      canvasKitBaseUrl: "canvaskit/",
    });
    window.clearTimeout(bootTimer);
    boot?.remove();
    await appRunner.runApp();
  },
});
