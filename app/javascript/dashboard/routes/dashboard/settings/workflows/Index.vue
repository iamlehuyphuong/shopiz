<script>
export default {
  name: 'WorkflowEmbed',
  mounted() {
    window.activepieces.configure({
      prefix: '/',
      instanceUrl: 'https://workflow-salesman.effiai.one',
      jwtToken:
        'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImZacnJMbDVQb29YU0RPaHZHMVZVMSJ9.eyJ2ZXJzaW9uIjoidjMiLCJleHRlcm5hbFVzZXJJZCI6IjEyMzQ1Njc4OSIsImV4dGVybmFsUHJvamVjdElkIjoib3JnLTEyMzQ1Njc4OSIsImZpcnN0TmFtZSI6IkhpZXAiLCJsYXN0TmFtZSI6IlRyYW4iLCJyb2xlIjoiRURJVE9SIiwicGllY2VzRmlsdGVyVHlwZSI6Ik5PTkUiLCJleHAiOjE4NTY1NjMyMDB9.aFtV8PFFW8vDOMKHSBZGFhmPMUEOxtjLy7thA16mVM8VUqpEMY0C92iOfU6UUx6JOa5YswKNiCVrFXsR8CzP6VUQ2BCn4vdBMBU9wSJD87NrWwURvtyAb4KZRQewXIil2FXtQyW4hIEnUQ1pkIFOF3nc7gKHgCp5mNLPD0LpuP1ds4bIwjQ_WdJvV0AeFr9fguDiEeqiayxeif1MbDgeYHFOkRFIAQi6hTEytuX07OvXfo03IIyvh91C1bQrskSoKNCzNTiYfCLH5X2B4iW_MihzQaT2y-zxw1OSCn-7C46LTz-8FmEh0hTf9J58yiHSKqpvM9mwK5ZtTMAG58RYGwZ_qCbWrJ5U2E00xp2J2OGti6tiBGHgpA9qvGS-G_NydlOtfBFbGrfUZgXd6um_ELaenqZ4PgIK9IjX6jRiSt-vLPGvO04Sf9sn4VzhmRV1qCMufXuQ4KwiF-NbFYKKEmrdkgJNefdZJPgT4chgmK7jPn3NYNkEhAzTS_B_5En1xjwfTckHsZctGSk0UO2vOA3V_UlI98Cb4gjUoElpfymOjpdecn6olIzU4Zoe78Bf59yq16csjrZmt-r6reHWi26Z2ux7zdbz84BowDpMVkoJ88iMdTME-Wq7cce7iSmMc3B-ed5jiu9go248fbQZt7EQQs1Xk1egdA6Nk07TrC8',
      embedding: {
        containerId: 'workflow-container',
        builder: {
          disableNavigation: true,
          hideLogo: true,
          hideFlowName: true,
        },
        dashboard: {
          hideSidebar: true,
        },
        hideFolders: true,
        navigation: {
          handler: ({ route }) => {
            // The iframe route has changed, make sure you check the navigation section.
            console.log(route);
          },
        },
      },
    });
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto">
    <div id="workflow-container" />
  </div>
</template>

<style lang="scss" scoped>
#workflow-container {
  width: 100%;
  height: 100vh;
}
iframe {
  width: 100%;
  height: 100vh;
}
</style>
