import { file, spawn } from "bun";

await installDependencies();
await installGitHooks();
await setupRemoteCache();

export async function installDependencies() {
  await spawn(["bun", "install"]).exited;
  console.log("Dependencies installed");
}

export async function installGitHooks() {
  await spawn(["bunx", "simple-git-hooks"]).exited;
  console.log("Git hooks installed");
}

export async function setupRemoteCache(isRetry?: boolean) {
  const config = file(".turbo/config.json");

  if (!((await config.exists()) && (await config.json()).teamId)) {
    const stdio = isRetry ? "inherit" : "pipe";
    const link = spawn(["turbo", "link"], { stdio: [stdio, stdio, stdio] });

    if ((await link.exited) !== 0) {
      const error = await new Response(link.stderr).text();
      if (error.includes("User not found")) {
        await spawn(["turbo", "login"]).exited;
        await setupRemoteCache();
        return;
      }
      if (error.includes("IO error")) {
        await setupRemoteCache(true);
        return;
      }
    }
  }

  console.log("Turbo remote cache configured");
}
