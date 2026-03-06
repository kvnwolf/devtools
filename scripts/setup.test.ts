import { beforeEach, describe, expect, test, vi } from "vitest";

const mockSpawn = vi.fn().mockReturnValue({
  exited: Promise.resolve(0),
  stderr: new Blob([""]),
});

const mockFile = vi.fn().mockReturnValue({
  exists: () => Promise.resolve(false),
  json: () => Promise.resolve({}),
});

vi.mock("bun", () => ({
  spawn: (...args: unknown[]) => mockSpawn(...args),
  file: (...args: unknown[]) => mockFile(...args),
}));

const { installDependencies, installGitHooks, setupRemoteCache } = await import("./setup");

function spawnReturns(exitCode: number, stderr = "") {
  return mockSpawn.mockReturnValue({
    exited: Promise.resolve(exitCode),
    stderr: new Blob([stderr]),
  });
}

function configReturns(exists: boolean, json: Record<string, unknown> = {}) {
  mockFile.mockReturnValue({
    exists: () => Promise.resolve(exists),
    json: () => Promise.resolve(json),
  });
}

beforeEach(() => {
  mockSpawn.mockClear();
  mockFile.mockClear();
  spawnReturns(0);
  configReturns(false);
});

describe("installDependencies", () => {
  test("runs bun install", async () => {
    await installDependencies();
    expect(mockSpawn).toHaveBeenCalledWith(["bun", "install"]);
  });
});

describe("installGitHooks", () => {
  test("runs bunx simple-git-hooks", async () => {
    await installGitHooks();
    expect(mockSpawn).toHaveBeenCalledWith(["bunx", "simple-git-hooks"]);
  });
});

describe("setupRemoteCache", () => {
  test("skips linking when config already has teamId", async () => {
    configReturns(true, { teamId: "team_123" });
    mockSpawn.mockClear();

    await setupRemoteCache();

    expect(mockSpawn).not.toHaveBeenCalledWith(["turbo", "link"], expect.anything());
  });

  test("runs turbo link with piped stdio on first attempt", async () => {
    await setupRemoteCache();

    expect(mockSpawn).toHaveBeenCalledWith(["turbo", "link"], {
      stdio: ["pipe", "pipe", "pipe"],
    });
  });

  test("runs turbo login then retries on 'User not found' error", async () => {
    mockSpawn
      .mockReturnValueOnce({
        exited: Promise.resolve(1),
        stderr: new Blob(["User not found"]),
      })
      .mockReturnValueOnce({ exited: Promise.resolve(0) })
      .mockReturnValueOnce({ exited: Promise.resolve(0) });
    configReturns(false);

    await setupRemoteCache();

    expect(mockSpawn).toHaveBeenCalledWith(["turbo", "login"]);
  });

  test("retries with inherited stdio on 'IO error'", async () => {
    mockSpawn
      .mockReturnValueOnce({
        exited: Promise.resolve(1),
        stderr: new Blob(["IO error"]),
      })
      .mockReturnValueOnce({ exited: Promise.resolve(0) });

    await setupRemoteCache();

    expect(mockSpawn).toHaveBeenCalledWith(["turbo", "link"], {
      stdio: ["inherit", "inherit", "inherit"],
    });
  });
});
