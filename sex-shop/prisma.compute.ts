import { defineComputeConfig } from "@prisma/compute-sdk/config";

export default defineComputeConfig({
  app: {
    name: "sex-shop",
    framework: "nextjs",
    env: ".env",
  },
});
