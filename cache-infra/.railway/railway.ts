import { readFileSync } from "node:fs";
import { defineRailway, image, postgres, preserve, project, service, volume } from "railway/iac";

export default defineRailway(() => {
  const Postgres = postgres("Postgres", { region: "us-east4-eqdc4a" });
  Postgres.networking = { privateNetworkEndpoint: "postgres" };
  const postgresVolume = volume("postgres-volume", { alerts: { usage: { "100": {}, "80": {}, "95": {} } }, allowOnlineResize: true, region: "us-east4-eqdc4a", sizeMB: 5000 });
  const atticd = service("atticd", {
    domains: ["nix.cmb.software"],
    source: image("ghcr.io/zhaofengli/attic:latest"),
    start: "atticd",
    healthcheck: "/",
    healthcheckTimeout: 30,
    replicas: { "us-east4-eqdc4a": 1 },
    deploy: { limitOverride: { containers: { cpu: 2, memoryBytes: 4000000000 } } },
    env: {
      ATTIC_SERVER_CONFIG_BASE64: readFileSync(new URL("../atticd-config.toml", import.meta.url)).toString("base64"),
      ATTIC_SERVER_DATABASE_URL: preserve(),
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64: preserve(),
      AWS_ACCESS_KEY_ID: preserve(),
      AWS_SECRET_ACCESS_KEY: preserve(),
    },
  });

  return project("attic-nix-cache", {
    resources: [Postgres, atticd, postgresVolume],
  });
});
