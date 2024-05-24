/** @type {import('tailwindcss').Config} */
import { fontFamily } from "tailwindcss/defaultTheme";

export const content = ["./index.html", "./src/**/*.{gleam,mjs}"];
export const theme = {
  extend: {
    fontFamily: {
      sans: ["InterVariable", ...fontFamily.sans],
    },
  },
};
export const plugins = [];
